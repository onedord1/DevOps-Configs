from ansible.plugins.callback import CallbackBase
import time
import datetime
import sys

class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'attractive_logger'
    
    # Icons for visual appeal
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
        'duration': '⏳'
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
        'cross': '┼'
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
        
    def create_boxed_text(self, text, width=80, icon=""):
        """Create a boxed text display"""
        if icon:
            text = f"{icon} {text}"
        
        # Ensure width is at least as long as the text
        text_width = len(text)
        if width < text_width + 4:
            width = text_width + 4
            
        # Top border
        top_border = f"{self.BOX_CHARS['corner_tl']}{self.BOX_CHARS['horizontal'] * (width - 2)}{self.BOX_CHARS['corner_tr']}"
        
        # Text line (centered)
        padding = (width - text_width - 2) // 2
        text_line = f"{self.BOX_CHARS['vertical']}{' ' * padding}{text}{' ' * (width - text_width - padding - 2)}{self.BOX_CHARS['vertical']}"
        
        # Bottom border
        bottom_border = f"{self.BOX_CHARS['corner_bl']}{self.BOX_CHARS['horizontal'] * (width - 2)}{self.BOX_CHARS['corner_br']}"
        
        return f"{top_border}\n{text_line}\n{bottom_border}"
        
    def create_progress_bar(self, current, total, width=50):
        """Create a visual progress bar"""
        if total == 0:
            return "[" + " " * width + "]"
            
        filled = int(width * current / total)
        bar = "█" * filled + " " * (width - filled)
        percentage = 100 * current / total
        
        return f"[{bar}] {percentage:.1f}% ({current}/{total})"
        
    def v2_playbook_on_start(self, playbook):
        header = self.create_boxed_text("ANSIBLE PLAYBOOK EXECUTION", 80, self.ICONS['start'])
        self._display.display(header)
        self._display.display(f"📁 Playbook: {playbook._file_name}")
        self._display.display(f"🕒 Started at: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        self._display.display("")
        
    def v2_playbook_on_play_start(self, play):
        self.current_play = play.get_name()
        play_header = self.create_boxed_text(f"PLAY: {self.current_play}", 70, self.ICONS['play'])
        self._display.display(play_header)
        
    def v2_playbook_on_task_start(self, task, is_conditional):
        task_name = task.get_name()
        if task_name and task_name != 'meta':
            self.task_count += 1
            self.current_task = task_name
            self.task_start_time = time.time()
            
            # Create a nice task header
            task_header = f"\n{self.BOX_CHARS['tee_left']}{self.BOX_CHARS['horizontal'] * 20} {self.ICONS['task']} TASK [{self.task_count}] {task_name}"
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
                status_line = f"  {self.ICONS['host']} {host}: {self.ICONS['changed']} CHANGED ({task_duration:.2f}s)"
                self._display.display(status_line)
                
                # Show what changed
                if result._result.get('cmd'):
                    cmd = " ".join(result._result['cmd']) if isinstance(result._result['cmd'], list) else result._result['cmd']
                    self._display.display(f"    {self.ICONS['command']} Command: {cmd}")
                    
                if result._result.get('changes'):
                    changes = result._result['changes']
                    if isinstance(changes, dict) and changes:
                        for key, value in changes.items():
                            self._display.display(f"    {self.ICONS['changed']} Changed: {key}")
                    else:
                        self._display.display(f"    {self.ICONS['changed']} Changes: {changes}")
            else:
                status_line = f"  {self.ICONS['host']} {host}: {self.ICONS['ok']} OK ({task_duration:.2f}s)"
                self._display.display(status_line)
                
            # Handle debug output with better formatting
            if result._result.get('msg') and task_name.startswith('Debug'):
                msg = result._result['msg']
                debug_header = f"    {self.ICONS['debug']} DEBUG OUTPUT:"
                self._display.display(debug_header)
                
                if isinstance(msg, str):
                    # Handle multi-line messages
                    lines = msg.split('\n')
                    for line in lines:
                        self._display.display(f"      {self.ICONS['output']} {line}")
                elif isinstance(msg, dict):
                    # Handle dict output
                    for key, value in msg.items():
                        self._display.display(f"      {self.ICONS['output']} {key}: {value}")
                        
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
            error_header = f"  {self.ICONS['error']} ERROR: {task_name} on {host}"
            self._display.error(error_header)
            self._display.error(f"    {self.ICONS['failed']} Status: FAILED ({task_duration:.2f}s)")
            self._display.error(f"    {self.ICONS['info']} Error: {error_msg}")
            
            # Show command if available
            if result._result.get('cmd'):
                cmd = " ".join(result._result['cmd']) if isinstance(result._result['cmd'], list) else result._result['cmd']
                self._display.error(f"    {self.ICONS['command']} Command: {cmd}")
                
            # Show stdout if available
            if result._result.get('stdout'):
                stdout = result._result['stdout']
                if isinstance(stdout, str) and '\n' in stdout:
                    self._display.error(f"    {self.ICONS['output']} STDOUT:")
                    for line in stdout.split('\n'):
                        self._display.error(f"      {line}")
                else:
                    self._display.error(f"    {self.ICONS['output']} STDOUT: {stdout}")
                
            # Show stderr if available
            if result._result.get('stderr'):
                stderr = result._result['stderr']
                if isinstance(stderr, str) and '\n' in stderr:
                    self._display.error(f"    {self.ICONS['error']} STDERR:")
                    for line in stderr.split('\n'):
                        self._display.error(f"      {line}")
                else:
                    self._display.error(f"    {self.ICONS['error']} STDERR: {stderr}")
                
            # Show exception if available
            if result._result.get('exception'):
                self._display.error(f"    {self.ICONS['error']} EXCEPTION: {result._result['exception']}")
                
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
            unreachable_header = f"  {self.ICONS['unreachable']} UNREACHABLE: {task_name} on {host}"
            self._display.error(unreachable_header)
            self._display.error(f"    {self.ICONS['info']} Error: {error_msg}")
            self._display.error(f"    {self.ICONS['duration']} Duration: {task_duration:.2f}s")
            
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
            
            self._display.display(f"  {self.ICONS['host']} {host}: {self.ICONS['skipped']} SKIPPED")
            
    def v2_playbook_on_stats(self, stats):
        # Calculate total execution time
        total_time = time.time() - self.start_time
        
        # Create completion header
        completion_header = self.create_boxed_text("PLAYBOOK EXECUTION COMPLETED", 80, self.ICONS['end'])
        self._display.display(completion_header)
        
        # Display execution stats
        self._display.display(f"{self.ICONS['time']} Total execution time: {total_time:.2f} seconds")
        self._display.display(f"{self.ICONS['stats']} Total tasks executed: {self.task_count}")
        
        # Display progress bar
        progress_bar = self.create_progress_bar(self.task_count, self.task_count)
        self._display.display(f"{self.ICONS['recap']} Progress: {progress_bar}")
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
                status_indicators.append(f"{self.ICONS['ok']} {s.get('ok', 0)}")
            if s.get('changed', 0) > 0:
                status_indicators.append(f"{self.ICONS['changed']} {s.get('changed', 0)}")
            if s.get('unreachable', 0) > 0:
                status_indicators.append(f"{self.ICONS['unreachable']} {s.get('unreachable', 0)}")
            if s.get('failed', 0) > 0:
                status_indicators.append(f"{self.ICONS['failed']} {s.get('failed', 0)}")
            if s.get('skipped', 0) > 0:
                status_indicators.append(f"{self.ICONS['skipped']} {s.get('skipped', 0)}")
                
            status_line = " | ".join(status_indicators)
            
            # Create a nice host status line
            host_status = f"  {self.ICONS['host']} {host}: {status_line}"
            self._display.display(host_status)
            
        # Display final status
        self._display.display("")
        total_failed = sum(stats.summarize(host).get('failed', 0) for host in hosts)
        total_unreachable = sum(stats.summarize(host).get('unreachable', 0) for host in hosts)
        
        if total_failed > 0 or total_unreachable > 0:
            failure_header = self.create_boxed_text("PLAYBOOK EXECUTION FAILED", 60, self.ICONS['failed'])
            self._display.error(failure_header)
            
            # Display detailed error summary
            if self.failed_tasks:
                error_summary_header = self.create_boxed_text("ERROR SUMMARY", 60, self.ICONS['error'])
                self._display.error(error_summary_header)
                
                for i, failure in enumerate(self.failed_tasks, 1):
                    error_line = f"  {i}. {failure['task']} on {failure['host']}: {failure['error']}"
                    self._display.error(error_line)
        else:
            success_header = self.create_boxed_text("PLAYBOOK EXECUTION SUCCEEDED", 60, self.ICONS['success'])
            self._display.display(success_header)
            
        # Display detailed task recap
        self._display.display("")
        task_recap_header = self.create_boxed_text("DETAILED TASK RECAP", 80, self.ICONS['recap'])
        self._display.display(task_recap_header)
        
        # Sort tasks by duration (longest first)
        sorted_tasks = sorted(self.task_details, key=lambda x: x['duration'], reverse=True)
        
        # Display top 20 longest tasks
        for i, task in enumerate(sorted_tasks[:20], 1):
            status_icon = self.ICONS.get(task['status'], '❓')
            task_line = f"  {i:2d}. {status_icon} {task['name']} ({task['duration']:.2f}s)"
            self._display.display(task_line)
            
        if len(sorted_tasks) > 20:
            self._display.display(f"  ... and {len(sorted_tasks) - 20} more tasks")
            
        # Display task summary
        self._display.display("")
        task_summary_header = self.create_boxed_text("TASK SUMMARY", 60, self.ICONS['stats'])
        self._display.display(task_summary_header)
        
        # Calculate statistics
        total_tasks = len(self.task_details)
        changed_tasks = sum(1 for task in self.task_details if task['status'] == 'changed')
        failed_tasks = sum(1 for task in self.task_details if task['status'] == 'failed')
        skipped_tasks = sum(1 for task in self.task_details if task['status'] == 'skipped')
        unreachable_tasks = sum(1 for task in self.task_details if task['status'] == 'unreachable')
        ok_tasks = sum(1 for task in self.task_details if task['status'] == 'ok')
        
        # Display statistics with icons
        self._display.display(f"  {self.ICONS['stats']} Total tasks: {total_tasks}")
        self._display.display(f"  {self.ICONS['changed']} Changed: {changed_tasks}")
        self._display.display(f"  {self.ICONS['ok']} OK: {ok_tasks}")
        self._display.display(f"  {self.ICONS['skipped']} Skipped: {skipped_tasks}")
        
        if failed_tasks > 0:
            self._display.display(f"  {self.ICONS['failed']} Failed: {failed_tasks}")
        if unreachable_tasks > 0:
            self._display.display(f"  {self.ICONS['unreachable']} Unreachable: {unreachable_tasks}")
            
        # Display average task duration
        if total_tasks > 0:
            avg_duration = sum(task['duration'] for task in self.task_details) / total_tasks
            self._display.display(f"  {self.ICONS['duration']} Average task duration: {avg_duration:.2f}s")