# -*- coding: utf-8 -*-
# =============================================================================
#  k8s_beautified  —  Midnight Cyberpunk stdout callback for Ansible
# =============================================================================
#  A polished, animated, high-signal terminal experience for kubeadm + Cilium
#  cluster automation. Features:
#    • Neon "midnight cyberpunk" truecolor theme
#    • Per-task braille spinner with live elapsed timer
#    • Smooth task-progression bar with percentage (per play)
#    • Rich, readable error panels (rc / stderr / stdout / msg)
#    • Animated banners, play headers and a final mission-report recap
#    • Loop-item + diff rendering
#
#  Safe by design: when stdout is not a TTY (e.g. piped to ansible.log) or when
#  NO_COLOR / ANSIBLE_NOCOLOR is set, all animation and color is disabled and a
#  clean plaintext stream is emitted instead.
#
#  Drop-in: configured via  stdout_callback = k8s_beautified  in ansible.cfg.
# =============================================================================

from __future__ import annotations

import os
import sys
import time
import threading

from ansible.plugins.callback import CallbackBase

try:
    from ansible import context as _ansible_context
except Exception:  # pragma: no cover - very old ansible
    _ansible_context = None


DOCUMENTATION = '''
    name: k8s_beautified
    type: stdout
    short_description: Midnight cyberpunk, animated Ansible output
    version_added: "2.14"
    description:
        - A neon, animated stdout callback tuned for kubeadm + Cilium runs.
        - Renders live spinners, per-play progress bars and rich error panels.
    requirements:
        - Set as stdout_callback in ansible.cfg
'''


# =============================================================================
#  Theme — Midnight Cyberpunk
# =============================================================================
class Theme(object):
    """Neon truecolor palette + glyphs. All escapes degrade to '' when colour
    is disabled so the same code path renders clean plaintext."""

    # 24-bit foreground colours (R, G, B)
    _PALETTE = {
        "magenta":  (255, 60, 172),   # neon hot-pink / magenta
        "pink":     (255, 121, 198),
        "cyan":     (80, 250, 255),    # electric cyan
        "blue":     (90, 170, 255),    # electric blue
        "purple":   (170, 120, 255),   # neon violet
        "green":    (80, 255, 170),    # mint neon
        "lime":     (160, 255, 80),
        "amber":    (255, 200, 90),    # warning amber
        "orange":   (255, 150, 70),
        "red":      (255, 80, 110),    # crimson alert
        "white":    (235, 240, 255),
        "fog":      (140, 150, 185),   # dim secondary text
        "ash":      (95, 105, 140),    # very dim / structure
        "deep":     (60, 70, 100),     # darkest structure
    }

    def __init__(self, enabled=True):
        self.enabled = enabled

    def fg(self, name):
        if not self.enabled:
            return ""
        r, g, b = self._PALETTE[name]
        return "\033[38;2;{};{};{}m".format(r, g, b)

    def bg(self, name):
        if not self.enabled:
            return ""
        r, g, b = self._PALETTE[name]
        return "\033[48;2;{};{};{}m".format(r, g, b)

    @property
    def reset(self):
        return "\033[0m" if self.enabled else ""

    @property
    def bold(self):
        return "\033[1m" if self.enabled else ""

    @property
    def dim(self):
        return "\033[2m" if self.enabled else ""

    @property
    def italic(self):
        return "\033[3m" if self.enabled else ""

    def paint(self, text, color, bold=False):
        if not self.enabled:
            return text
        b = self.bold if bold else ""
        return "{}{}{}{}".format(b, self.fg(color), text, self.reset)

    # ---- glyphs (Unicode, terminal-safe, not emoji) ------------------------
    SPINNER = ["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"]
    PULSE = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃", "▂"]

    G_OK = "✔"
    G_CHANGED = "✸"
    G_FAIL = "✖"
    G_SKIP = "▸"
    G_UNREACH = "⚡"
    G_RESCUE = "↺"
    G_PLAY = "◆"
    G_TASK = "›"
    G_HANDLER = "⚙"
    G_ARROW = "➜"
    G_DOT = "•"
    G_BOLT = "⚡"


# =============================================================================
#  Spinner — background animation thread that updates a single line in place
# =============================================================================
class Spinner(object):
    """Drives a single, in-place animated line. All formatting (and crucially,
    width-capping so the line never wraps) is delegated to a `render` callback
    of the form ``render(frame_index, elapsed_seconds) -> str``."""

    def __init__(self, stream, enabled, render):
        self.stream = stream
        self.enabled = enabled
        self.render = render
        self._thread = None
        self._stop = threading.Event()
        self._start = 0.0
        self._lock = threading.Lock()

    def start(self):
        if not self.enabled:
            return
        self.stop()
        self._start = time.time()
        self._stop.clear()
        self._thread = threading.Thread(target=self._spin, daemon=True)
        self._thread.start()

    def _spin(self):
        i = 0
        while not self._stop.is_set():
            elapsed = time.time() - self._start
            try:
                line = self.render(i, elapsed)
            except Exception:
                line = ""
            with self._lock:
                self.stream.write("\r\033[K" + line)
                self.stream.flush()
            i += 1
            self._stop.wait(0.08)
        with self._lock:
            self.stream.write("\r\033[K")
            self.stream.flush()

    def stop(self):
        if self._thread and self._thread.is_alive():
            self._stop.set()
            self._thread.join(timeout=1.0)
        self._thread = None


# =============================================================================
#  CallbackModule
# =============================================================================
class CallbackModule(CallbackBase):

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "k8s_beautified"
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self):
        super(CallbackModule, self).__init__()

        self.stream = sys.stdout
        self.colors_enabled = self._supports_color()
        self.anim_enabled = self.colors_enabled and self.stream.isatty()

        self.t = Theme(enabled=self.colors_enabled)
        self.spinner = Spinner(self.stream, enabled=self.anim_enabled,
                               render=self._render_spinner)

        # run-wide state
        self._play_index = 0
        self._task_in_play = 0
        self._task_total = 0          # best-effort total for current play
        self._run_start = time.time()
        self._task_start = time.time()
        self._task_header_done = False
        self._current_task_name = ""
        self._playbook_name = ""
        self._spin_host = ""
        self._task_glyph = Theme.G_TASK

        # per-task host result rollup for nicer grouping
        self._host_results = []

    # ------------------------------------------------------------------ utils
    @staticmethod
    def _supports_color():
        if os.environ.get("NO_COLOR") is not None:
            return False
        if os.environ.get("ANSIBLE_NOCOLOR") is not None:
            return False
        if os.environ.get("ANSIBLE_FORCE_COLOR") is not None:
            return True
        return sys.stdout.isatty()

    def _term_width(self):
        try:
            return max(60, min(120, os.get_terminal_size().columns))
        except Exception:
            return 100

    def _emit(self, text=""):
        """Print a line, making sure any live spinner is cleared first."""
        self.spinner.stop()
        self.stream.write(text + "\n")
        self.stream.flush()

    def _rule(self, color="ash", char="─"):
        return self.t.paint(char * self._term_width(), color)

    def _fmt_time(self, seconds):
        if seconds < 60:
            return "{:0.1f}s".format(seconds)
        m, s = divmod(int(seconds), 60)
        if m < 60:
            return "{}m{:02d}s".format(m, s)
        h, m = divmod(m, 60)
        return "{}h{:02d}m{:02d}s".format(h, m, s)

    # --------------------------------------------------------- progress bar
    def _bar_segment(self, width=20, anim_index=None):
        """Return (visible_text, colored_text) for the progress indicator.
        Determinate when the play task total is known, otherwise an animated
        neon 'scanner' bar (when anim_index is given) or a static counter."""
        t = self.t
        if self._task_total and self._task_total > 0:
            pct = min(100, int(round(self._task_in_play / float(self._task_total) * 100)))
            filled = max(0, min(width, int(round(width * pct / 100.0))))
            if pct >= 80:
                col = "cyan"
            elif pct >= 40:
                col = "purple"
            else:
                col = "magenta"
            label = "{:>3d}%".format(pct)
            vis = "⟦" + "█" * filled + "░" * (width - filled) + "⟧ " + label
            colored = (
                t.paint("⟦", "ash")
                + t.paint("█" * filled, col, bold=True)
                + t.paint("░" * (width - filled), "deep")
                + t.paint("⟧", "ash") + " "
                + t.paint(label, col, bold=True)
            )
            return vis, colored

        # ---- indeterminate ------------------------------------------------
        counter = "#{:03d}".format(self._task_in_play)
        if anim_index is None:
            vis = "⟦" + "░" * width + "⟧ " + counter
            colored = (
                t.paint("⟦", "ash") + t.paint("░" * width, "deep")
                + t.paint("⟧", "ash") + " " + t.paint(counter, "purple", bold=True)
            )
            return vis, colored
        seg = 4
        span = max(1, width - seg)
        cycle = span * 2
        p = anim_index % cycle
        pos = p if p <= span else cycle - p
        left = "░" * pos
        right = "░" * (width - seg - pos)
        vis = "⟦" + left + "█" * seg + right + "⟧ " + counter
        colored = (
            t.paint("⟦", "ash")
            + t.paint(left, "deep")
            + t.paint("█" * seg, "cyan", bold=True)
            + t.paint(right, "deep")
            + t.paint("⟧", "ash") + " "
            + t.paint(counter, "purple", bold=True)
        )
        return vis, colored

    def _count_play_tasks(self, play):
        """Best-effort count of tasks in a play. Roles expand lazily, so this
        returns 0 for role-based plays — in which case an indeterminate bar is
        shown instead of a misleading percentage."""
        try:
            count = 0
            for block in play.get_tasks():
                for task in block:
                    action = getattr(task, "action", "")
                    if action in ("meta", "include_role", "import_role",
                                  "include_tasks", "import_tasks"):
                        continue
                    count += 1
            return count
        except Exception:
            return 0

    # ============================================================ PLAYBOOK
    def v2_playbook_on_start(self, playbook):
        self._playbook_name = os.path.basename(playbook._file_name)
        t = self.t
        w = self._term_width()
        title = "K U B E A D M   ·   C I L I U M   D E P L O Y M E N T"
        self._emit()
        self._emit(t.paint("╔" + "═" * (w - 2) + "╗", "purple"))
        self._emit(
            t.paint("║", "purple")
            + t.paint(self._center(title, w - 2), "cyan", bold=True)
            + t.paint("║", "purple")
        )
        sub = "midnight theme ansible  {}  {}".format(t.G_BOLT, self._playbook_name)
        self._emit(
            t.paint("║", "purple")
            + self.t.fg("magenta") + self._center(sub, w - 2) + t.reset
            + t.paint("║", "purple")
        )
        self._emit(t.paint("╚" + "═" * (w - 2) + "╝", "purple"))
        self._emit()

    def _center(self, text, width):
        if len(text) >= width:
            return text[:width]
        pad = width - len(text)
        left = pad // 2
        right = pad - left
        return " " * left + text + " " * right

    # ============================================================ PLAY
    def v2_playbook_on_play_start(self, play):
        self._play_index += 1
        self._task_in_play = 0
        self._task_total = self._count_play_tasks(play)
        name = play.get_name().strip() or "play"
        t = self.t
        w = self._term_width()
        self._emit()
        self._emit(self._rule("deep", "━"))
        header = "{glyph} PLAY {idx:02d} {arrow} {name}".format(
            glyph=t.G_PLAY, idx=self._play_index, arrow=t.G_ARROW, name=name
        )
        self._emit(t.paint(" " + header, "magenta", bold=True))
        self._emit(self._rule("deep", "━"))

    # ============================================================ TASK
    def v2_playbook_on_task_start(self, task, is_conditional):
        self._begin_task(task, kind="task")

    def v2_playbook_on_handler_task_start(self, task):
        self._begin_task(task, kind="handler")

    def _begin_task(self, task, kind="task"):
        self._task_in_play += 1
        if self._task_total and self._task_in_play > self._task_total:
            self._task_total = self._task_in_play  # keep bar honest, never >100%
        self._task_start = time.time()
        self._task_header_done = False
        self._host_results = []
        self._spin_host = ""
        name = task.get_name().strip() or "task"
        self._current_task_name = name
        self._task_glyph = self.t.G_HANDLER if kind == "handler" else self.t.G_TASK
        # kick off the live spinner; the header prints when results land
        self.spinner.start()
        if not self.anim_enabled:
            # static fallback line for non-tty / no-color
            self._print_task_header(running=True)

    def _render_spinner(self, i, elapsed):
        """Build a single, width-capped spinner line so it never wraps (which
        is what previously caused stacked/garbled progress bars)."""
        t = self.t
        frame = t.SPINNER[i % len(t.SPINNER)]
        pulse = t.PULSE[i % len(t.PULSE)]
        timer = "[{}]".format(self._fmt_time(elapsed))
        glyph = getattr(self, "_task_glyph", t.G_TASK)
        bar_vis, bar_col = self._bar_segment(anim_index=i)
        host = self._spin_host
        name = self._current_task_name

        # visible skeleton (no name) -> compute remaining budget for the name
        host_vis = (host + " ❯ ") if host else ""
        left_vis = "┃ {sp} {pu} {bar} {g} {hv}".format(
            sp=frame, pu=pulse, bar=bar_vis, g=glyph, hv=host_vis)
        right_vis = " " + timer
        budget = self._term_width() - len(left_vis) - len(right_vis) - 1
        if budget < 6:
            budget = 6
        short = name if len(name) <= budget else name[:budget - 1] + "…"

        return (
            t.paint("┃", "purple") + " "
            + t.paint(frame, "cyan", bold=True) + " "
            + t.paint(pulse, "magenta") + " "
            + bar_col + " "
            + t.paint(glyph, "purple", bold=True) + " "
            + (t.paint(host, "cyan") + t.paint(" ❯ ", "ash") if host else "")
            + t.paint(short, "white")
            + " " + t.fg("ash") + timer + t.reset
        )

    def _print_task_header(self, running=False):
        if self._task_header_done:
            return
        self._task_header_done = True
        t = self.t
        glyph = getattr(self, "_task_glyph", t.G_TASK)
        bar_vis, bar_col = self._bar_segment()
        # cap the task name so the header never wraps either
        left_vis = "┏ {bar} {g} ".format(bar=bar_vis, g=glyph)
        budget = self._term_width() - len(left_vis) - 1
        if budget < 6:
            budget = 6
        name = self._current_task_name
        short = name if len(name) <= budget else name[:budget - 1] + "…"
        line = "{lead} {bar} {g} {name}".format(
            lead=t.paint("┏", "purple"),
            bar=bar_col,
            g=t.paint(glyph, "purple", bold=True),
            name=t.paint(short, "white", bold=True),
        )
        self._emit(line)

    # ============================================================ RESULTS
    def _host_of(self, result):
        try:
            return result._host.get_name()
        except Exception:
            return "host"

    def _result_line(self, glyph, color, host, label, extra=""):
        t = self.t
        elapsed = self._fmt_time(time.time() - self._task_start)
        return "{lead} {g} {host} {dot} {label}{extra} {dim}[{tmr}]{rst}".format(
            lead=t.paint("┗", color),
            g=t.paint(glyph, color, bold=True),
            host=t.paint("{:<12}".format(host), color),
            dot=t.paint(t.G_DOT, "ash"),
            label=t.paint(label, color),
            extra=(" " + extra) if extra else "",
            dim=t.fg("ash"),
            tmr=elapsed,
            rst=t.reset,
        )

    def v2_runner_on_ok(self, result):
        self._print_task_header()
        host = self._host_of(result)
        changed = result._result.get("changed", False)
        if changed:
            glyph, color, label = self.t.G_CHANGED, "amber", "changed"
        else:
            glyph, color, label = self.t.G_OK, "green", "ok"
        extra = self._inline_summary(result._result)
        self._emit(self._result_line(glyph, color, host, label, extra))

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self._print_task_header()
        host = self._host_of(result)
        if ignore_errors:
            self._emit(self._result_line(self.t.G_SKIP, "fog", host,
                                         "failed (ignored)"))
        else:
            self._emit(self._result_line(self.t.G_FAIL, "red", host, "failed"))
        self._error_panel(result._result, host, ignored=ignore_errors)

    def v2_runner_on_skipped(self, result):
        self._print_task_header()
        host = self._host_of(result)
        self._emit(self._result_line(self.t.G_SKIP, "fog", host, "skipped"))

    def v2_runner_on_unreachable(self, result):
        self._print_task_header()
        host = self._host_of(result)
        self._emit(self._result_line(self.t.G_UNREACH, "orange", host,
                                     "unreachable"))
        self._error_panel(result._result, host, unreachable=True)

    # ---- loop items --------------------------------------------------------
    def _item_label(self, result):
        try:
            item = result._result.get("item")
            if item is None:
                return ""
            text = str(item)
            return text if len(text) <= 48 else text[:45] + "…"
        except Exception:
            return ""

    def v2_runner_item_on_ok(self, result):
        self._print_task_header()
        host = self._host_of(result)
        changed = result._result.get("changed", False)
        glyph, color = (self.t.G_CHANGED, "amber") if changed else (self.t.G_OK, "green")
        item = self._item_label(result)
        t = self.t
        self._emit("{lead}   {g} {dim}item:{rst} {it}".format(
            lead=t.paint("┃", "ash"),
            g=t.paint(glyph, color),
            dim=t.fg("ash"),
            rst=t.reset,
            it=t.paint(item, "fog"),
        ))

    def v2_runner_item_on_failed(self, result):
        self._print_task_header()
        t = self.t
        item = self._item_label(result)
        self._emit("{lead}   {g} {dim}item:{rst} {it}".format(
            lead=t.paint("┃", "red"),
            g=t.paint(t.G_FAIL, "red"),
            dim=t.fg("ash"),
            rst=t.reset,
            it=t.paint(item, "red"),
        ))

    def v2_runner_item_on_skipped(self, result):
        return  # keep loops quiet on skip to reduce noise

    # ============================================================ HELPERS
    def _inline_summary(self, res):
        """A compact, neon-dim hint of what a module did (rc / results count)."""
        t = self.t
        bits = []
        rc = res.get("rc")
        if rc is not None and rc != 0:
            bits.append(t.paint("rc={}".format(rc), "amber"))
        if "results" in res and isinstance(res["results"], list):
            bits.append(t.paint("items={}".format(len(res["results"])), "fog"))
        if res.get("skipped"):
            bits.append(t.paint("skipped", "fog"))
        return " ".join(bits)

    def _error_panel(self, res, host, ignored=False, unreachable=False):
        """Render a readable, fully-closed framed error box."""
        t = self.t
        accent = "orange" if unreachable else ("fog" if ignored else "red")
        title = ("UNREACHABLE" if unreachable
                 else ("ERROR (ignored)" if ignored else "TASK FAILED"))

        margin = "  "
        bw = max(40, self._term_width() - len(margin))
        inner = bw - 4

        # ---- box drawing helpers (visible-width aware) --------------------
        def top():
            k = bw - 5 - len(title)
            k = max(0, k)
            return margin + t.paint("┌─ " + title + " " + "─" * k + "┐", accent, bold=True)

        def bottom():
            return margin + t.paint("└" + "─" * (bw - 2) + "┘", accent)

        def line(text, text_color="white", bold=False):
            text = str(text).replace("\t", "    ")
            if len(text) > inner:
                text = text[:inner]
            pad = inner - len(text)
            return (margin + t.paint("│ ", accent)
                    + t.paint(text, text_color, bold=bold)
                    + " " * pad + t.paint(" │", accent))

        def section(label, value, vcolor="white"):
            self._emit(line(label, text_color=accent, bold=True))
            for raw in str(value).splitlines() or [""]:
                raw = raw.replace("\t", "    ")
                if raw == "":
                    self._emit(line("", text_color=vcolor))
                    continue
                for j in range(0, len(raw), inner):
                    self._emit(line(raw[j:j + inner], text_color=vcolor))

        self._emit(top())

        msg = res.get("msg")
        if msg:
            section("message", msg, vcolor="white")

        rc = res.get("rc")
        if rc is not None:
            self._emit(line("exit code  {}".format(rc), text_color="amber", bold=True))

        seen = set()
        for key, lbl in (("module_stderr", "stderr"), ("stderr", "stderr"),
                         ("module_stdout", "stdout"), ("stdout", "stdout")):
            val = res.get(key)
            if val and str(val).strip() and lbl not in seen:
                seen.add(lbl)
                section(lbl, str(val).strip(), vcolor="white")

        exc = res.get("exception")
        if exc and not (msg or rc):
            section("exception", str(exc).strip(), vcolor="white")

        if not (msg or rc is not None or seen or exc):
            section("result", str(res), vcolor="fog")

        self._emit(bottom())

    # ---- diff --------------------------------------------------------------
    def v2_on_file_diff(self, result):
        diff = result._result.get("diff")
        if not diff:
            return
        self._print_task_header()
        if not isinstance(diff, list):
            diff = [diff]
        t = self.t
        for d in diff:
            if not isinstance(d, dict):
                continue
            text = self._get_diff(d)
            for line in text.splitlines():
                if line.startswith("+") and not line.startswith("+++"):
                    self._emit(t.paint("  ┃ " + line, "green"))
                elif line.startswith("-") and not line.startswith("---"):
                    self._emit(t.paint("  ┃ " + line, "red"))
                elif line.startswith("@@"):
                    self._emit(t.paint("  ┃ " + line, "cyan"))
                else:
                    self._emit(t.paint("  ┃ " + line, "fog"))

    # ---- misc events -------------------------------------------------------
    def v2_playbook_on_no_hosts_matched(self):
        self._emit(self.t.paint("  {} no hosts matched".format(self.t.G_SKIP), "amber"))

    def v2_runner_on_start(self, host, task):
        # reflect the active host in the live spinner line
        if self.anim_enabled and not self._task_header_done:
            self._spin_host = host.get_name()

    # ============================================================ RECAP
    def v2_playbook_on_stats(self, stats):
        self.spinner.stop()
        t = self.t
        w = self._term_width()
        total_elapsed = self._fmt_time(time.time() - self._run_start)

        self._emit()
        self._emit(t.paint("╔" + "═" * (w - 2) + "╗", "cyan"))
        self._emit(
            t.paint("║", "cyan")
            + t.paint(self._center("M I S S I O N   R E P O R T", w - 2), "cyan", bold=True)
            + t.paint("║", "cyan")
        )
        self._emit(t.paint("╚" + "═" * (w - 2) + "╝", "cyan"))

        hosts = sorted(stats.processed.keys())
        any_failure = False
        for host in hosts:
            s = stats.summarize(host)
            failed = s["failures"] > 0 or s["unreachable"] > 0
            any_failure = any_failure or failed
            verdict_glyph = t.G_FAIL if failed else t.G_OK
            verdict_col = "red" if failed else "green"

            cells = [
                self._stat_cell(t.G_OK, "ok", s["ok"], "green"),
                self._stat_cell(t.G_CHANGED, "changed", s["changed"], "amber"),
                self._stat_cell(t.G_FAIL, "failed", s["failures"], "red"),
                self._stat_cell(t.G_UNREACH, "unreach", s["unreachable"], "orange"),
                self._stat_cell(t.G_SKIP, "skipped", s["skipped"], "fog"),
            ]
            self._emit(
                " {g} {host} {bar}".format(
                    g=t.paint(verdict_glyph, verdict_col, bold=True),
                    host=t.paint("{:<14}".format(host), verdict_col, bold=True),
                    bar="  ".join(cells),
                )
            )

        self._emit(self._rule("deep", "─"))
        verdict = "DEPLOYMENT FAILED" if any_failure else "DEPLOYMENT SUCCEEDED"
        vcol = "red" if any_failure else "green"
        vglyph = t.G_FAIL if any_failure else t.G_OK
        self._emit(
            " {g} {v}   {dim}{dot} elapsed {tmr}{rst}".format(
                g=t.paint(vglyph, vcol, bold=True),
                v=t.paint(verdict, vcol, bold=True),
                dim=t.fg("fog"),
                dot=t.G_DOT,
                tmr=total_elapsed,
                rst=t.reset,
            )
        )
        self._emit()

    def _stat_cell(self, glyph, label, count, color):
        t = self.t
        if count:
            return "{g} {lbl} {n}".format(
                g=t.paint(glyph, color, bold=True),
                lbl=t.paint(label, color),
                n=t.paint(str(count), color, bold=True),
            )
        return "{g} {lbl} {n}".format(
            g=t.paint(glyph, "deep"),
            lbl=t.paint(label, "deep"),
            n=t.paint(str(count), "deep"),
        )
