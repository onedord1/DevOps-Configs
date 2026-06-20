"""k8s_beautified — a polished, emoji-free stdout callback for Ansible.

Design goals (per user feedback):
  - NO block-character bars (no █ ░). Use slim line meters instead.
  - Live spinner / loader animation while each task runs (real TTY only).
  - Cohesive, non-eye-burning color theme (soft palette, one accent).
  - Honest progress: an absolute cumulative task counter (#N) plus a per-play
    percentage only when the play total is reliably known.

Renders:
  - a soft-bordered banner per playbook run
  - per-play header with host counts
  - a spinner-prefixed task line while the task is in flight
  - compact color-coded per-host result lines
  - a bordered, readable error panel on failure (no raw tracebacks)
  - a beautified PLAY RECAP table and a final summary panel

Override any time with:  ANSIBLE_STDOUT_CALLBACK=default
"""
from __future__ import annotations

import datetime
import os
import sys
import threading
import time

from ansible.plugins.callback import CallbackBase

try:
    from rich import box
    from rich.console import Console, Group
    from rich.panel import Panel
    from rich.spinner import Spinner
    from rich.table import Table
    from rich.text import Text
    from rich.live import Live
except Exception:  # pragma: no cover - rich is a hard dep, but stay safe
    box = None
    Console = None
    Panel = None
    Spinner = None
    Table = None
    Text = None
    Live = None


# =============================================================================
# Color theme — soft, low-saturation, one cyan accent. NOT eye-burning.
# Tuned for dark terminals (the common case). Works acceptably on light too.
# =============================================================================
class Theme:
    accent       = "cyan"          # banner / titles / accent
    accent_dim   = "bright_black"  # rules, dim labels
    ok           = "green"
    changed      = "yellow"
    skipped      = "bright_cyan"
    failed       = "bold red"
    unreachable  = "bold magenta"
    rescued      = "green"
    ignored      = "bright_black"
    host         = "white"
    play         = "blue"
    spinner      = "cyan"
    meter        = "cyan"


STYLES = {
    "ok":          Theme.ok,
    "changed":     Theme.changed,
    "skipped":     Theme.skipped,
    "failed":      Theme.failed,
    "unreachable": Theme.unreachable,
    "rescued":     Theme.rescued,
    "ignored":     Theme.ignored,
}

LABELS = {
    "ok":          "ok",
    "changed":     "changed",
    "skipped":     "skipped",
    "failed":      "FAILED",
    "unreachable": "UNREACHABLE",
    "rescued":     "rescued",
    "ignored":     "ignored",
}

# Spinner frames that animate. dots2/arc are calm; bouncingBar is line-based.
SPINNER_NAME = os.environ.get("K8S_LOG_SPINNER", "dots2")
# Per-host result truncation
_MAX_FIELD = 1500
_MAX_EXC_LINES = 8


def _fmt_duration(seconds: float) -> str:
    return str(datetime.timedelta(seconds=int(seconds)))


class _LiveLoader:
    """In-place task loader using Rich's Live display.

    Uses Live (which issues proper ANSI cursor-control sequences) instead of
    raw carriage returns, so the spinner animates on one line instead of
    stacking frames. Only activates on a real TTY; no-op when piped/logged.
    """

    def __init__(self, console: Console, label: str):
        self._console = console
        self._label = label
        self._live: Live | None = None
        self._thread: threading.Thread | None = None
        self._stop = threading.Event()

    def start(self):
        if not self._console.is_terminal:
            return
        try:
            spinner = Spinner(SPINNER_NAME, text=self._label, style=Theme.spinner)
            # transient=True so the spinner line vanishes cleanly when stopped,
            # and refresh_per_second caps the redraw rate.
            self._live = Live(spinner, console=self._console,
                              transient=True, refresh_per_second=10,
                              vertical_overflow="visible")
            self._live.start()
        except Exception:
            self._live = None

    def stop(self):
        if self._live is not None:
            try:
                self._live.stop()
            except Exception:
                pass
            self._live = None



class CallbackModule(CallbackBase):
    """Beautified stdout callback."""

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "k8s_beautified"
    CALLBACK_NEEDS_ENABLED = False

    def __init__(self, display=None, options=None):
        super().__init__(display=display, options=options)
        self._has_rich = Console is not None
        if self._has_rich:
            self._console = Console(
                force_terminal=None,
                width=int(os.environ.get("COLUMNS", 0)) or None,
                highlight=False,
                soft_wrap=False,
            )
        else:
            self._console = None
        # run state
        self._start = time.time()
        self._play_start = self._start
        self._play_name = ""
        self._play_total = 0
        self._play_seen = 0      # tasks actually started in this play
        self._grand_seen = 0     # cumulative task counter across playbook
        self._counts = {
            "ok": 0, "changed": 0, "skipped": 0,
            "failed": 0, "unreachable": 0, "ignored": 0, "rescued": 0,
        }
        self._loader: _LiveLoader | None = None

    # -- low-level emit ------------------------------------------------------
    def _emit(self, renderable, style=None, end="\n"):
        if not self._has_rich:
            print(str(renderable), end=end)
            return
        if style and not isinstance(renderable, (Text, Panel, Table)):
            renderable = Text(str(renderable), style=style)
        self._console.print(renderable, end=end, crop=True, overflow="ignore")

    def _line(self, text: str, style: str | None = None):
        self._emit(text, style=style)

    def _rule(self, char: str = "-", length: int = 70, style: str = Theme.accent_dim):
        self._emit(Text(char * length, style=style))

    # -- loader lifecycle ---------------------------------------------------
    def _start_spinner(self, label: str):
        self._stop_spinner()
        if not self._has_rich:
            return
        self._loader = _LiveLoader(self._console, label)
        self._loader.start()

    def _stop_spinner(self):
        if self._loader is not None:
            self._loader.stop()
            self._loader = None

    # -- helpers -------------------------------------------------------------
    def _estimate_play_tasks(self, play) -> int:
        """Best-effort total tasks (facts + pre + main + post) for a play."""
        total = 0
        try:
            if getattr(play, "gather_facts", None) not in (None, False):
                total += 1
            for attr in ("pre_tasks", "tasks", "post_tasks"):
                blocks = getattr(play, attr, None) or []
                for block in blocks:
                    inner = getattr(block, "block", None)
                    if isinstance(inner, list):
                        total += len(inner)
                    else:
                        total += 1
        except Exception:
            return 0
        return total

    def _status_for(self, result) -> str:
        try:
            if result.is_unreachable:
                return "unreachable"
            if result.is_failed:
                return "failed"
        except Exception:
            pass
        r = result._result or {}
        if r.get("skipped"):
            return "skipped"
        if r.get("changed"):
            return "changed"
        return "ok"

    def _truncate(self, value: str, limit: int = _MAX_FIELD) -> str:
        value = value.strip()
        if len(value) <= limit:
            return value
        return value[:limit] + f"\n  ... [truncated {len(value) - limit} chars]"

    def _tail_exception(self, exc: str) -> str:
        lines = [ln for ln in exc.splitlines() if ln.strip()]
        if len(lines) <= _MAX_EXC_LINES:
            return "\n".join(lines)
        return "  ...\n" + "\n".join(lines[-_MAX_EXC_LINES:])

    def _extract_error_fields(self, result):
        r = result._result or {}
        fields = []
        if r.get("msg"):
            fields.append(("Message", self._truncate(str(r["msg"]))))
        if r.get("stderr"):
            fields.append(("stderr", self._truncate(str(r["stderr"]))))
        if r.get("stdout"):
            fields.append(("stdout", self._truncate(str(r["stdout"]))))
        if r.get("cmd"):
            cmd = r["cmd"]
            if isinstance(cmd, list):
                cmd = " ".join(str(c) for c in cmd)
            fields.append(("Command", self._truncate(str(cmd), 400)))
        if not fields and r.get("exception"):
            fields.append(("Exception", self._tail_exception(str(r["exception"]))))
        if not fields:
            fields.append(("Detail", self._truncate(str(r))))
        return fields

    def _meter(self, pct: float) -> Text:
        """Slim line meter instead of block chars:  [~~~~------] 62%"""
        width = 18
        pct = max(0.0, min(100.0, float(pct)))
        filled = int(round(width * pct / 100.0))
        bar = Text()
        bar.append("\u2502", style=Theme.meter)
        bar.append("~" * filled, style=Theme.meter)
        bar.append("-" * (width - filled), style=Theme.accent_dim)
        bar.append("\u2502", style=Theme.meter)
        bar.append(f" {pct:5.1f}%", style=Theme.meter)
        return bar

    # ======================================================================
    # Playbook lifecycle
    # ======================================================================
    def v2_playbook_on_start(self, playbook):
        self._start = time.time()
        self._play_start = self._start
        self._grand_seen = 0
        for k in self._counts:
            self._counts[k] = 0
        fname = getattr(playbook, "_file_name", "playbook")
        when = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        inv = os.environ.get("ANSIBLE_INVENTORY", "(default)")
        body = Text()
        body.append("PLAYBOOK  ", style="bold " + Theme.accent)
        body.append(os.path.basename(fname), style=Theme.host)
        body.append(f"\npath        {fname}", style=Theme.accent_dim)
        body.append(f"\ninventory   {inv}", style=Theme.accent_dim)
        body.append(f"\nstarted     {when}", style=Theme.accent_dim)
        if self._has_rich:
            self._emit(Panel(body, border_style=Theme.accent, box=box.ROUNDED,
                             title=Text("ansible", style="bold " + Theme.accent),
                             title_align="left", padding=(0, 1)))
        else:
            self._rule("=")
            self._line(str(body))
            self._rule("=")

    def v2_playbook_on_play_start(self, play):
        self._play_start = time.time()
        self._play_seen = 0
        self._play_name = getattr(play, "name", "") or "(unnamed)"
        self._play_total = self._estimate_play_tasks(play)
        n_hosts = 0
        try:
            n_hosts = len(play.hosts) if play.hosts else 0
        except Exception:
            pass
        title = Text()
        title.append("PLAY ", style="bold " + Theme.play)
        title.append(f"[{self._play_name}]", style="bold " + Theme.host)
        title.append(f"  -  {n_hosts} host(s)", style=Theme.accent_dim)
        self._emit(title)
        self._rule(style=Theme.play)

    def v2_playbook_on_no_hosts_matched(self):
        self._line("  (no hosts matched)", Theme.changed)

    def v2_playbook_on_no_hosts_remaining(self):
        self._line("  (no hosts remaining - all failed/unreachable)", Theme.failed)

    # ======================================================================
    # Tasks + runner results
    # ======================================================================
    def v2_playbook_on_task_start(self, task, is_conditional):
        self._stop_spinner()
        self._play_seen += 1
        self._grand_seen += 1
        try:
            task_name = task.get_name()
        except Exception:
            task_name = str(task)

        # Per-play percentage only when the play total is reliable.
        if self._play_total > 0:
            pct = (self._play_seen / self._play_total) * 100.0
            meter = self._meter(pct)
            prog = f"#{self._grand_seen}  play {self._play_seen}/{self._play_total}"
        else:
            # Role-based plays can't be pre-counted cleanly -> show absolute only
            meter = Text(f"running", style=Theme.accent_dim)
            prog = f"#{self._grand_seen}"

        line = Text()
        line.append("TASK ", style="bold")
        line.append(f"[{task_name}] ", style=Theme.accent)
        line.append(prog + "   ", style=Theme.accent_dim)
        line.append(meter)
        elapsed = time.time() - self._play_start
        line.append(f"  {_fmt_duration(elapsed)}", style=Theme.accent_dim)
        self._emit(line)

        # Start the loader animation for this task.
        self._start_spinner(f"  running: {task_name}")

    def v2_runner_on_start(self, host, task):
        pass

    def _render_result(self, result, status=None):
        self._stop_spinner()
        status = status or self._status_for(result)
        try:
            host = result._host.get_name()
        except Exception:
            host = "?"
        try:
            task = result._task.get_name()
        except Exception:
            task = ""
        style = STYLES.get(status, Theme.host)
        label = LABELS.get(status, status)
        line = Text("  ")
        line.append(f"{label}:", style=style)
        line.append(f" [{host}]", style=Theme.host)
        r = result._result or {}
        inv = r.get("invocation") or {}
        mod = inv.get("module_name")
        if mod:
            line.append(f"  ({mod})", style=Theme.accent_dim)
        if status == "changed":
            line.append("  *", style=Theme.changed)
        self._emit(line)

    def v2_runner_on_ok(self, result):
        self._counts["ok"] += 1
        self._render_result(result, "ok")

    def v2_runner_item_on_ok(self, result):
        if result._result.get("changed"):
            self._counts["changed"] += 1
            self._render_result(result, "changed")

    def v2_runner_on_changed(self, result):
        self._counts["changed"] += 1
        self._render_result(result, "changed")

    def v2_runner_on_skipped(self, result):
        self._counts["skipped"] += 1
        self._render_result(result, "skipped")

    def v2_runner_item_on_skipped(self, result):
        self._counts["skipped"] += 1

    def v2_runner_retry(self, result):
        self._stop_spinner()
        try:
            host = result._host.get_name()
        except Exception:
            host = "?"
        r = result._result or {}
        attempts = r.get("attempts", "?")
        self._line(f"  retry: [{host}] attempt {attempts}", Theme.changed)

    def v2_runner_on_unreachable(self, result):
        self._counts["unreachable"] += 1
        self._render_result(result, "unreachable")
        self._error_panel(result, status="unreachable")

    def v2_runner_on_failed(self, result, ignore_errors=False):
        if ignore_errors:
            self._counts["ignored"] += 1
        else:
            self._counts["failed"] += 1
        self._render_result(result, "failed" if not ignore_errors else "ignored")
        self._error_panel(result, status="failed" if not ignore_errors else "ignored",
                          ignore_errors=ignore_errors)

    def v2_runner_item_on_failed(self, result):
        self._error_panel(result, status="failed", item=True)

    def _error_panel(self, result, status="failed", ignore_errors=False, item=False):
        """Bordered, readable error block - never dumps raw tracebacks."""
        try:
            host = result._host.get_name()
        except Exception:
            host = "?"
        try:
            task = result._task.get_name()
        except Exception:
            task = "(unknown task)"
        fields = self._extract_error_fields(result)
        body = Text()
        body.append("Host   ", style=Theme.accent_dim)
        body.append(host, style=Theme.host)
        body.append("\nTask   ", style=Theme.accent_dim)
        body.append(task, style=Theme.host)
        if item:
            r = result._result or {}
            it = r.get("item")
            if it is not None:
                body.append("\nItem   ", style=Theme.accent_dim)
                body.append(self._truncate(str(it), 300), style=Theme.host)
        for label, value in fields:
            body.append(f"\n{label:<7}", style=Theme.accent_dim)
            body.append("\n  " + value, style=Theme.host)
        border = Theme.failed if status == "failed" else (
            Theme.unreachable if status == "unreachable" else Theme.changed)
        title = Text(LABELS.get(status, status), style="bold " + border)
        if ignore_errors:
            title.append("  (ignored)", style=Theme.accent_dim)
        if self._has_rich:
            self._emit(Panel(body, title=title, title_align="left",
                             border_style=border, box=box.HEAVY,
                             padding=(0, 1)))
        else:
            self._rule("*", style=border)
            self._line(str(title), border)
            self._line(str(body))
            self._rule("*", style=border)

    # ======================================================================
    # Stats / summary
    # ======================================================================
    def v2_playbook_on_stats(self, stats):
        self._stop_spinner()
        self._rule("=", length=70, style=Theme.accent)
        cols = [
            ("host",         "left",  False),
            ("ok",           "right", True),
            ("changed",      "right", True),
            ("unreachable",  "right", True),
            ("failed",       "right", True),
            ("skipped",      "right", True),
            ("rescued",      "right", True),
            ("ignored",      "right", True),
        ]
        table = Table(title=Text("PLAY RECAP", style="bold " + Theme.accent),
                      box=box.SIMPLE_HEAVY, header_style="bold",
                      border_style=Theme.accent, expand=False, padding=(0, 1))
        for name, justify, _ in cols:
            label = {"unreachable": "unreach"}.get(name, name)
            table.add_column(label, overflow="ellipsis", no_wrap=True,
                             justify=justify)

        hosts = list(stats.processed.keys()) if stats.processed else []
        try:
            hosts = sorted(hosts)
        except Exception:
            pass

        for host in hosts:
            s = stats.summarize(host)
            row = [host, str(s.get("ok", 0)), str(s.get("changed", 0)),
                   str(s.get("dark", 0)), str(s.get("failures", 0)),
                   str(s.get("skipped", 0)), str(s.get("rescued", 0)),
                   str(s.get("ignored", 0))]
            if s.get("failures") or s.get("dark"):
                style = Theme.failed
            elif s.get("changed"):
                style = Theme.changed
            else:
                style = Theme.ok
            table.add_row(*[Text(c, style=style) for c in row])

        if self._has_rich:
            self._emit(table)
        else:
            for host in hosts:
                self._line("  " + str(stats.summarize(host)), Theme.host)

        # final summary panel
        elapsed = time.time() - self._start
        c = self._counts
        failed = c["failed"] + c["unreachable"]
        overall = Theme.failed if failed else (Theme.changed if c["changed"] else Theme.ok)
        verdict = "FAILED" if failed else ("CHANGED" if c["changed"] else "SUCCESS")
        summary = Text()
        summary.append("result    ", style=Theme.accent_dim)
        summary.append(verdict, style="bold " + overall)
        summary.append(f"\nduration  ", style=Theme.accent_dim)
        summary.append(_fmt_duration(elapsed), style=Theme.host)
        summary.append(f"\ntasks     ", style=Theme.accent_dim)
        summary.append(f"#{self._grand_seen} executed", style=Theme.host)
        summary.append(f"\ntotals    ", style=Theme.accent_dim)
        summary.append(
            f"ok={c['ok']}  changed={c['changed']}  skipped={c['skipped']}  "
            f"failed={c['failed']}  unreachable={c['unreachable']}  "
            f"rescued={c['rescued']}  ignored={c['ignored']}",
            style=Theme.host,
        )
        if self._has_rich:
            self._emit(Panel(summary, border_style=overall, box=box.ROUNDED,
                             title=Text("playbook result", style="bold " + Theme.accent),
                             title_align="left", padding=(0, 1)))
        else:
            self._rule("=", style=overall)
            self._line(str(summary), overall)
            self._rule("=", style=overall)

