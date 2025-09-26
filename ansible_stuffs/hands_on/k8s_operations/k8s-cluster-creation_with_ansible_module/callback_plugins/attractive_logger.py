from ansible.plugins.callback import CallbackBase
import time
import datetime
import sys

class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'attractive_logger'
    
    # Enhanced color scheme
    COLORS = {
        'play': 'blue',
        'task': 'cyan',
        'ok': 'green',
        'changed': 'yellow',
        'failed': 'red',
        'skipped': 'cyan',
        'unreachable': 'bright red',
        'start': 'green',
        'end': 'blue',
        'info': 'blue',
        'warning': 'yellow',
        'time': 'magenta',
        'host': 'white',
        'stats': 'blue',
        'recap': 'cyan',
        'success': 'green',
        'error': 'red',
        'debug': 'blue',
        'command': 'yellow',
        'output': 'green',
        'duration': 'magenta',
        'box': 'blue',
        'progress': 'green',
        'header': 'bright white'
    }
    
    # Enhanced icons for visual appeal
    ICONS = {
        'play': '🎭',
        'task': '📋',
        'ok': '✅',
        'changed': '🔄',
        'failed': '❌',
        'skipped': '⏭️',
        'unreachable': '🚫',
        'start': '🚀',
        'end': '🏁',
        'info': 'ℹ️',
        'warning': '⚠️',
        'time': '⏱️',
        'host': '🖥️',
        'stats': '📊',
        'recap': '📝',
        'success': '🎉',
        'error': '💥',
        'debug': '🔍',
        'command': '💻',
        'output': '📄',
        'duration': '⏳',
        'progress': '📈',
        'summary': '📋',
        'details': '🔎',
        'performance': '⚡'
    }
    
    # Box drawing characters for visual appeal
    BOX_CHARS = {
        'horizontal': '─',
        'vertical': '│',
        'corner_tl': '╭',
        'corner_tr': '╮',
        'corner_bl': '╰',
        'corner_br': '╯',
        'tee_left': '├',
        'tee_right': '┤',
        'tee_up': '┬',
        'tee_down': '┴',
        'cross': '┼',
        'double_horizontal': '═',
        'double_vertical': '║',
        'double_corner_tl': '╔',
        'double_corner_tr': '╗',
        'double_corner_bl': '╚',
        'double_corner_br': '╝'
    }
    
    def __init__(self):
        super(CallbackModule, self).__init__()
        self.start_time = time.time()
        self.current_play = None
        self.task_count = 0
        self.current_task = None
        self.host_stats = {}
        self.task_start_time = None
        self.failed_tasks = []
        self.task_details = []  # Store task details for recap
        self.play_start_time = None
        
    def color_text(self, text, color):
        """Apply color to text"""
        color_name = self.COLORS.get(color, 'white')
        try:
            # Try with positional arguments (older Ansible versions)
            from ansible.utils.color import colorize
            return colorize(text, color_name, 0)
        except (ImportError, TypeError):
            # If that fails, try without the num parameter
            try:
                from ansible.utils.color import colorize
                return colorize(text, color=color_name)
            except (ImportError, TypeError):
                # If colorize is not available or doesn't work, return plain text
                return text
        
    def create_boxed_text(self, text, width=80, icon="", color='box'):
        """Create a boxed text display with colors"""
        if icon:
            text = f"{icon} {text}"
        
        # Ensure width is at least as long as the text
        text_width = len(text)
        if width < text_width + 4:
            width = text_width + 4
            
        # Top border with color
        top_border = self.color_text(
            f"{self.BOX_CHARS['corner_tl']}{self.BOX_CHARS['horizontal'] * (width - 2)}{self.BOX_CHARS['corner_tr']}", 
            color
        )
        
        # Text line (centered) with color
        padding = (width - text_width - 2) // 2
        text_line = (
            self.color_text(self.BOX_CHARS['vertical'], color) +
            self.color_text(' ' * padding + text + ' ' * (width - text_width - padding - 2), 'header') +
            self.color_text(self.BOX_CHARS['vertical'], color)
        )
        
        # Bottom border with color
        bottom_border = self.color_text(
            f"{self.BOX_CHARS['corner_bl']}{self.BOX_CHARS['horizontal'] * (width - 2)}{self.BOX_CHARS['corner_br']}", 
            color
        )
        
        return f"{top_border}\n{text_line}\n{bottom_border}"
        
    def create_double_boxed_text(self, text, width=80, icon="", color='box'):
        """Create a double-boxed text display for emphasis"""
        if icon:
            text = f"{icon} {text}"
        
        # Ensure width is at least as long as the text
        text_width = len(text)
        if width < text_width + 6:
            width = text_width + 6
            
        # Outer box
        outer_top = self.color_text(
            f"{self.BOX_CHARS['double_corner_tl']}{self.BOX_CHARS['double_horizontal'] * (width - 2)}{self.BOX_CHARS['double_corner_tr']}", 
            color
        )
        outer_bottom = self.color_text(
            f"{self.BOX_CHARS['double_corner_bl']}{self.BOX_CHARS['double_horizontal'] * (width - 2)}{self.BOX_CHARS['double_corner_br']}", 
            color
        )
        
        # Inner box
        inner_top = self.color_text(
            f" {self.BOX_CHARS['corner_tl']}{self.BOX_CHARS['horizontal'] * (width - 4)}{self.BOX_CHARS['corner_tr']} ", 
            color
        )
        inner_bottom = self.color_text(
            f" {self.BOX_CHARS['corner_bl']}{self.BOX_CHARS['horizontal'] * (width - 4)}{self.BOX_CHARS['corner_br']} ", 
            color
        )
        
        # Text line (centered)
        padding = (width - text_width - 6) // 2
        text_line = (
            self.color_text(f" {self.BOX_CHARS['vertical']}", color) +
            self.color_text(' ' * padding + text + ' ' * (width - text_width - padding - 6), 'header') +
            self.color_text(f"{self.BOX_CHARS['vertical']} ", color)
        )
        
        return f"{outer_top}\n{inner_top}\n{text_line}\n{inner_bottom}\n{outer_bottom}"
        
    def create_progress_bar(self, current, total, width=50, color='progress'):
        """Create a visual progress bar with colors"""
        if total == 0:
            return "[" + " " * width + "]"
            
        filled = int(width * current / total)
        bar = self.color_text("█" * filled, color) + " " * (width - filled)
        percentage = 100 * current / total
        
        return f"[{bar}] {self.color_text(f'{percentage:.1f}%', 'header')} ({current}/{total})"
        
    def create_status_bar(self, stats):
        """Create a status bar showing task distribution"""
        total = stats['ok'] + stats['changed'] + stats['failed'] + stats['skipped'] + stats['unreachable']
        if total == 0:
            return ""
            
        ok_width = int(50 * stats['ok'] / total)
        changed_width = int(50 * stats['changed'] / total)
        failed_width = int(50 * stats['failed'] / total)
        skipped_width = int(50 * stats['skipped'] / total)
        unreachable_width = int(50 * stats['unreachable'] / total)
        
        bar = (
            self.color_text("█" * ok_width, 'ok') +
            self.color_text("█" * changed_width, 'changed') +
            self.color_text("█" * failed_width, 'failed') +
            self.color_text("█" * skipped_width, 'skipped') +
            self.color_text("█" * unreachable_width, 'unreachable') +
            " " * (50 - ok_width - changed_width - failed_width - skipped_width - unreachable_width)
        )
        
        return f"[{bar}]"
        
    def v2_playbook_on_start(self, playbook):
        header = self.create_double_boxed_text("ANSIBLE PLAYBOOK EXECUTION", 80, self.ICONS['start'])
        self._display.display(header)
        self._display.display(f"📁 Playbook: {self.color_text(playbook._file_name, 'info')}")
        self._display.display(f"🕒 Started at: {self.color_text(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), 'time')}")
        self._display.display("")
        
    def v2_playbook_on_play_start(self, play):
        self.play_start_time = time.time()
        self.current_play = play.get_name()
        play_header = self.create_boxed_text(f"PLAY: {self.current_play}", 70, self.ICONS['play'], 'play')
        self._display.display(play_header)
        
    def v2_playbook_on_task_start(self, task, is_conditional):
        task_name = task.get_name()
        if task_name and task_name != 'meta':
            self.task_count += 1
            self.current_task = task_name
            self.task_start_time = time.time()
            
            # Create a nice task header
            task_header = f"\n{self.color_text(self.BOX_CHARS['tee_left'], 'task')}{self.color_text(self.BOX_CHARS['horizontal'] * 20, 'task')} {self.ICONS['task']} TASK [{self.color_text(str(self.task_count), 'header')}] {self.color_text(task_name, 'task')}"
            self._display.display(task_header)
            
    def v2_runner_on_ok(self, result):
        task_name = result._task.get_name()
        if task_name and task_name != 'meta':
            host = result._host.get_name()
            changed = result._result.get('changed', False)
            
            # Calculate task duration
            task_duration = time.time() - self.task_start_time if self.task_start_time else 0
            
            # Store task details for recap
            self.task_details.append({
                'name': task_name,
                'host': host,
                'status': 'changed' if changed else 'ok',
                'duration': task_duration,
                'changed': changed
            })
            
            if changed:
                status_icon = self.ICONS['changed']
                status_color = 'changed'
                status_text = 'CHANGED'
            else:
                status_icon = self.ICONS['ok']
                status_color = 'ok'
                status_text = 'OK'
                
            status_line = f"  {self.ICONS['host']} {self.color_text(host, 'host')}: {self.color_text(status_icon, status_color)} {self.color_text(status_text, status_color)} ({self.color_text(f'{task_duration:.2f}s', 'duration')})"
            self._display.display(status_line)
            
            # Show what changed
            if result._result.get('cmd'):
                cmd = " ".join(result._result['cmd']) if isinstance(result._result['cmd'], list) else result._result['cmd']
                self._display.display(f"    {self.ICONS['command']} {self.color_text('Command:', 'command')} {self.color_text(cmd, 'output')}")
                
            if result._result.get('changes'):
                changes = result._result['changes']
                if isinstance(changes, dict) and changes:
                    for key, value in changes.items():
                        self._display.display(f"    {self.ICONS['changed']} {self.color_text('Changed:', 'changed')} {self.color_text(str(key), 'output')}")
                else:
                    self._display.display(f"    {self.ICONS['changed']} {self.color_text('Changes:', 'changed')} {self.color_text(str(changes), 'output')}")
                    
    def v2_runner_on_failed(self, result, ignore_errors=False):
        task_name = result._task.get_name()
        if task_name and task_name != 'meta':
            host = result._host.get_name()
            error_msg = result._result.get('msg', 'Unknown error')
            
            # Calculate task duration
            task_duration = time.time() - self.task_start_time if self.task_start_time else 0
            
            # Store task details for recap
            self.failed_tasks.append({
                'task': task_name,
                'host': host,
                'error': error_msg,
                'duration': task_duration
            })
            
            self.task_details.append({
                'name': task_name,
                'host': host,
                'status': 'failed',
                'duration': task_duration,
                'error': error_msg
            })
            
            # Create a prominent error display
            error_header = f"  {self.ICONS['error']} {self.color_text('ERROR:', 'failed')} {self.color_text(task_name, 'failed')} {self.color_text('on', 'error')} {self.color_text(host, 'host')}"
            self._display.error(error_header)
            self._display.error(f"    {self.ICONS['failed']} {self.color_text('Status:', 'error')} {self.color_text('FAILED', 'failed')} ({self.color_text(f'{task_duration:.2f}s', 'duration')})")
            self._display.error(f"    {self.ICONS['info']} {self.color_text('Error:', 'error')} {self.color_text(error_msg, 'error')}")
            
            # Show command if available
            if result._result.get('cmd'):
                cmd = " ".join(result._result['cmd']) if isinstance(result._result['cmd'], list) else result._result['cmd']
                self._display.error(f"    {self.ICONS['command']} {self.color_text('Command:', 'command')} {self.color_text(cmd, 'output')}")
                
            # Show stdout if available
            if result._result.get('stdout'):
                stdout = result._result['stdout']
                if isinstance(stdout, str) and '\n' in stdout:
                    self._display.error(f"    {self.ICONS['output']} {self.color_text('STDOUT:', 'output')}")
                    for line in stdout.split('\n'):
                        self._display.error(f"      {self.color_text(line, 'output')}")
                else:
                    self._display.error(f"    {self.ICONS['output']} {self.color_text('STDOUT:', 'output')} {self.color_text(stdout, 'output')}")
                
            # Show stderr if available
            if result._result.get('stderr'):
                stderr = result._result['stderr']
                if isinstance(stderr, str) and '\n' in stderr:
                    self._display.error(f"    {self.ICONS['error']} {self.color_text('STDERR:', 'error')}")
                    for line in stderr.split('\n'):
                        self._display.error(f"      {self.color_text(line, 'error')}")
                else:
                    self._display.error(f"    {self.ICONS['error']} {self.color_text('STDERR:', 'error')} {self.color_text(stderr, 'error')}")
                
            # Show exception if available
            if result._result.get('exception'):
                self._display.error(f"    {self.ICONS['error']} {self.color_text('EXCEPTION:', 'error')} {self.color_text(result._result['exception'], 'error')}")
                
    def v2_runner_on_unreachable(self, result):
        task_name = result._task.get_name()
        if task_name and task_name != 'meta':
            host = result._host.get_name()
            error_msg = result._result.get('msg', 'Unreachable')
            
            # Calculate task duration
            task_duration = time.time() - self.task_start_time if self.task_start_time else 0
            
            # Store task details for recap
            self.failed_tasks.append({
                'task': task_name,
                'host': host,
                'error': error_msg,
                'duration': task_duration
            })
            
            self.task_details.append({
                'name': task_name,
                'host': host,
                'status': 'unreachable',
                'duration': task_duration,
                'error': error_msg
            })
            
            # Create a prominent unreachable display
            unreachable_header = f"  {self.ICONS['unreachable']} {self.color_text('UNREACHABLE:', 'unreachable')} {self.color_text(task_name, 'unreachable')} {self.color_text('on', 'error')} {self.color_text(host, 'host')}"
            self._display.error(unreachable_header)
            self._display.error(f"    {self.ICONS['info']} {self.color_text('Error:', 'error')} {self.color_text(error_msg, 'error')}")
            self._display.error(f"    {self.ICONS['duration']} {self.color_text('Duration:', 'duration')} {self.color_text(f'{task_duration:.2f}s', 'duration')}")
            
    def v2_runner_on_skipped(self, result):
        task_name = result._task.get_name()
        if task_name and task_name != 'meta':
            host = result._host.get_name()
            
            # Store task details for recap
            self.task_details.append({
                'name': task_name,
                'host': host,
                'status': 'skipped',
                'duration': 0
            })
            
            self._display.display(f"  {self.ICONS['host']} {self.color_text(host, 'host')}: {self.ICONS['skipped']} {self.color_text('SKIPPED', 'skipped')}")
            
    def v2_playbook_on_stats(self, stats):
        # Calculate total execution time
        total_time = time.time() - self.start_time
        
        # Create completion header
        completion_header = self.create_double_boxed_text("PLAYBOOK EXECUTION COMPLETED", 80, self.ICONS['end'])
        self._display.display(completion_header)
        
        # Display execution stats
        self._display.display(f"{self.ICONS['time']} {self.color_text('Total execution time:', 'time')} {self.color_text(f'{total_time:.2f} seconds', 'duration')}")
        self._display.display(f"{self.ICONS['stats']} {self.color_text('Total tasks executed:', 'stats')} {self.color_text(str(self.task_count), 'header')}")
        
        # Display progress bar
        progress_bar = self.create_progress_bar(self.task_count, self.task_count)
        self._display.display(f"{self.ICONS['recap']} {self.color_text('Progress:', 'recap')} {progress_bar}")
        self._display.display("")
        
        # Display host summary with better formatting
        host_summary_header = self.create_boxed_text("HOST SUMMARY", 70, self.ICONS['host'])
        self._display.display(host_summary_header)
        
        hosts = sorted(stats.processed.keys())
        for host in hosts:
            s = stats.summarize(host)
            
            # Create status indicators with safe access
            status_indicators = []
            if s.get('ok', 0) > 0:
                status_indicators.append(f"{self.ICONS['ok']} {self.color_text(str(s.get('ok', 0)), 'ok')}")
            if s.get('changed', 0) > 0:
                status_indicators.append(f"{self.ICONS['changed']} {self.color_text(str(s.get('changed', 0)), 'changed')}")
            if s.get('unreachable', 0) > 0:
                status_indicators.append(f"{self.ICONS['unreachable']} {self.color_text(str(s.get('unreachable', 0)), 'unreachable')}")
            if s.get('failed', 0) > 0:
                status_indicators.append(f"{self.ICONS['failed']} {self.color_text(str(s.get('failed', 0)), 'failed')}")
            if s.get('skipped', 0) > 0:
                status_indicators.append(f"{self.ICONS['skipped']} {self.color_text(str(s.get('skipped', 0)), 'skipped')}")
                
            status_line = " | ".join(status_indicators)
            
            # Create a nice host status line
            host_status = f"  {self.ICONS['host']} {self.color_text(host, 'host')}: {status_line}"
            self._display.display(host_status)
            
        # Display final status
        self._display.display("")
        total_failed = sum(stats.summarize(host).get('failed', 0) for host in hosts)
        total_unreachable = sum(stats.summarize(host).get('unreachable', 0) for host in hosts)
        
        if total_failed > 0 or total_unreachable > 0:
            failure_header = self.create_boxed_text("PLAYBOOK EXECUTION FAILED", 60, self.ICONS['failed'], 'failed')
            self._display.error(failure_header)
            
            # Display detailed error summary
            if self.failed_tasks:
                error_summary_header = self.create_boxed_text("ERROR SUMMARY", 60, self.ICONS['error'], 'error')
                self._display.error(error_summary_header)
                
                for i, failure in enumerate(self.failed_tasks, 1):
                    error_line = f"  {i}. {self.color_text(failure['task'], 'failed')} {self.color_text('on', 'error')} {self.color_text(failure['host'], 'host')}: {self.color_text(failure['error'], 'error')}"
                    self._display.error(error_line)
        else:
            success_header = self.create_boxed_text("PLAYBOOK EXECUTION SUCCEEDED", 60, self.ICONS['success'], 'success')
            self._display.display(success_header)
            
        # Display detailed task recap
        self._display.display("")
        task_recap_header = self.create_boxed_text("DETAILED TASK RECAP", 80, self.ICONS['recap'])
        self._display.display(task_recap_header)
        
        # Group tasks by status
        tasks_by_status = {
            'failed': [],
            'unreachable': [],
            'changed': [],
            'ok': [],
            'skipped': []
        }
        
        for task in self.task_details:
            tasks_by_status[task['status']].append(task)
            
        # Display failed tasks
        if tasks_by_status['failed']:
            failed_text = f"{self.ICONS['failed']} FAILED TASKS:"
            self._display.display(f"\n{self.color_text(failed_text, 'failed')}")
            for task in sorted(tasks_by_status['failed'], key=lambda x: x['duration'], reverse=True):
                duration_text = f"{task['duration']:.2f}s"
                task_line = f"  • {self.color_text(task['name'], 'failed')} ({self.color_text(duration_text, 'duration')}) {self.color_text('on', 'error')} {self.color_text(task['host'], 'host')}"
                self._display.display(task_line)
                
        # Display unreachable tasks
        if tasks_by_status['unreachable']:
            unreachable_text = f"{self.ICONS['unreachable']} UNREACHABLE TASKS:"
            self._display.display(f"\n{self.color_text(unreachable_text, 'unreachable')}")
            for task in sorted(tasks_by_status['unreachable'], key=lambda x: x['duration'], reverse=True):
                duration_text = f"{task['duration']:.2f}s"
                task_line = f"  • {self.color_text(task['name'], 'unreachable')} ({self.color_text(duration_text, 'duration')}) {self.color_text('on', 'error')} {self.color_text(task['host'], 'host')}"
                self._display.display(task_line)
                
        # Display changed tasks
        if tasks_by_status['changed']:
            changed_text = f"{self.ICONS['changed']} CHANGED TASKS:"
            self._display.display(f"\n{self.color_text(changed_text, 'changed')}")
            for task in sorted(tasks_by_status['changed'], key=lambda x: x['duration'], reverse=True)[:10]:  # Top 10
                duration_text = f"{task['duration']:.2f}s"
                task_line = f"  • {self.color_text(task['name'], 'changed')} ({self.color_text(duration_text, 'duration')}) {self.color_text('on', 'info')} {self.color_text(task['host'], 'host')}"
                self._display.display(task_line)
            if len(tasks_by_status['changed']) > 10:
                self._display.display(f"  ... and {len(tasks_by_status['changed']) - 10} more changed tasks")
                
        # Display OK tasks (top 10 longest)
        if tasks_by_status['ok']:
            ok_text = f"{self.ICONS['ok']} OK TASKS (Top 10 longest):"
            self._display.display(f"\n{self.color_text(ok_text, 'ok')}")
            for task in sorted(tasks_by_status['ok'], key=lambda x: x['duration'], reverse=True)[:10]:
                duration_text = f"{task['duration']:.2f}s"
                task_line = f"  • {self.color_text(task['name'], 'ok')} ({self.color_text(duration_text, 'duration')}) {self.color_text('on', 'info')} {self.color_text(task['host'], 'host')}"
                self._display.display(task_line)
            if len(tasks_by_status['ok']) > 10:
                self._display.display(f"  ... and {len(tasks_by_status['ok']) - 10} more OK tasks")
                
        # Display skipped tasks
        if tasks_by_status['skipped']:
            skipped_text = f"{self.ICONS['skipped']} SKIPPED TASKS:"
            self._display.display(f"\n{self.color_text(skipped_text, 'skipped')}")
            for task in tasks_by_status['skipped']:
                task_line = f"  • {self.color_text(task['name'], 'skipped')} {self.color_text('on', 'info')} {self.color_text(task['host'], 'host')}"
                self._display.display(task_line)
                
        # Display task summary
        self._display.display("")
        task_summary_header = self.create_boxed_text("TASK SUMMARY", 60, self.ICONS['summary'])
        self._display.display(task_summary_header)
        
        # Calculate statistics
        total_tasks = len(self.task_details)
        changed_tasks = sum(1 for task in self.task_details if task['status'] == 'changed')
        failed_tasks = sum(1 for task in self.task_details if task['status'] == 'failed')
        skipped_tasks = sum(1 for task in self.task_details if task['status'] == 'skipped')
        unreachable_tasks = sum(1 for task in self.task_details if task['status'] == 'unreachable')
        ok_tasks = sum(1 for task in self.task_details if task['status'] == 'ok')
        
        # Display statistics with icons
        self._display.display(f"  {self.ICONS['stats']} {self.color_text('Total tasks:', 'stats')} {self.color_text(str(total_tasks), 'header')}")
        self._display.display(f"  {self.ICONS['changed']} {self.color_text('Changed:', 'changed')} {self.color_text(str(changed_tasks), 'changed')}")
        self._display.display(f"  {self.ICONS['ok']} {self.color_text('OK:', 'ok')} {self.color_text(str(ok_tasks), 'ok')}")
        self._display.display(f"  {self.ICONS['skipped']} {self.color_text('Skipped:', 'skipped')} {self.color_text(str(skipped_tasks), 'skipped')}")
        
        if failed_tasks > 0:
            self._display.display(f"  {self.ICONS['failed']} {self.color_text('Failed:', 'failed')} {self.color_text(str(failed_tasks), 'failed')}")
        if unreachable_tasks > 0:
            self._display.display(f"  {self.ICONS['unreachable']} {self.color_text('Unreachable:', 'unreachable')} {self.color_text(str(unreachable_tasks), 'unreachable')}")
            
        # Display average task duration
        if total_tasks > 0:
            avg_duration = sum(task['duration'] for task in self.task_details) / total_tasks
            avg_text = f"{avg_duration:.2f}s"
            self._display.display(f"  {self.ICONS['duration']} {self.color_text('Average task duration:', 'duration')} {self.color_text(avg_text, 'duration')}")
            
        # Display status distribution bar
        stats_dict = {
            'ok': ok_tasks,
            'changed': changed_tasks,
            'failed': failed_tasks,
            'skipped': skipped_tasks,
            'unreachable': unreachable_tasks
        }
        status_bar = self.create_status_bar(stats_dict)
        if status_bar:
            self._display.display(f"\n  {self.ICONS['progress']} {self.color_text('Status Distribution:', 'progress')}")
            self._display.display(f"    {status_bar}")
            self._display.display(f"    {self.ICONS['ok']} OK {self.ICONS['changed']} CHANGED {self.ICONS['failed']} FAILED {self.ICONS['skipped']} SKIPPED {self.ICONS['unreachable']} UNREACHABLE")