#!/usr/bin/env python3
import os
import subprocess
import sys
import re
import time
import threading
import json
from datetime import datetime
from itertools import cycle
from collections import deque

# Define directories
script_dir = os.path.dirname(os.path.realpath(__file__))
venv_dir = os.path.join(script_dir, 'ansible-venv')
logs_dir = os.path.join(script_dir, 'logs')
log_file = os.path.join(logs_dir, f'ansible_setup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

# Ensure logs directory exists
os.makedirs(logs_dir, exist_ok=True)

# Colors for terminal output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# Spinner animation
spinner = cycle(['-', '/', '|', '\\'])

# Global variables to track tasks
task_stats = {
    'total': 0,
    'completed': 0,
    'changed': 0,
    'failed': 0,
    'skipped': 0,
    'rescued': 0,
    'ignored': 0,
    'tasks': []
}

# Function to show a spinner for long-running tasks
def show_spinner(message, stop_event, duration=None):
    start_time = time.time()
    while not stop_event.is_set():
        for char in spinner:
            if stop_event.is_set():
                break
            elapsed = int(time.time() - start_time)
            sys.stdout.write(f'\r{Colors.OKCYAN}{message} {char} [{elapsed}s]{Colors.ENDC}')
            sys.stdout.flush()
            time.sleep(0.1)
            if duration and elapsed >= duration:
                stop_event.set()
                break
    sys.stdout.write('\r\033[K')  # Clear the line

# Function to create a progress bar
def progress_bar(current, total, prefix='', suffix='', length=30):
    percent = 100 * (current / total)
    filled_length = int(length * current // total)
    bar = '█' * filled_length + '-' * (length - filled_length)
    sys.stdout.write(f'\r{prefix} |{bar}| {percent:.1f}% {suffix}')
    sys.stdout.flush()

# Function to log messages
def log(message, color=None, level='INFO'):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Format based on log level
    if level == 'SUCCESS':
        formatted_msg = f"{Colors.OKGREEN}[✓ SUCCESS]{Colors.ENDC} {message}"
    elif level == 'ERROR':
        formatted_msg = f"{Colors.FAIL}[✗ ERROR]{Colors.ENDC} {message}"
    elif level == 'WARNING':
        formatted_msg = f"{Colors.WARNING}[! WARNING]{Colors.ENDC} {message}"
    elif level == 'INFO':
        formatted_msg = f"{Colors.OKBLUE}[i INFO]{Colors.ENDC} {message}"
    elif level == 'TASK':
        formatted_msg = f"{Colors.OKCYAN}[→ TASK]{Colors.ENDC} {message}"
    elif level == 'PLAY':
        formatted_msg = f"{Colors.HEADER}[▶ PLAY]{Colors.ENDC} {message}"
    else:
        formatted_msg = message
    
    print(formatted_msg)
    
    # Write to log file without colors
    with open(log_file, 'a') as f:
        f.write(f'{timestamp} - {level} - {message}\n')

# Function to show usage
def show_usage():
    print(f"{Colors.HEADER}Usage: python3 run_me.py [environment]{Colors.ENDC}")
    print(f"{Colors.OKCYAN}Available environments: dev, staging, prod{Colors.ENDC}")
    print(f"{Colors.OKGREEN}Example: python3 run_me.py dev{Colors.ENDC}")
    sys.exit(1)

# Function to process Ansible output and add progress indicators
def process_ansible_output(process, stop_event):
    current_play = None
    current_task = None
    task_start_time = None
    
    while True:
        line = process.stdout.readline()
        if not line and process.poll() is not None:
            break
        if line:
            line = line.strip()
            
            # Detect playbook starts
            play_match = re.match(r'PLAY \[(.*)\]', line)
            if play_match:
                current_play = play_match.group(1)
                log(f"Starting play: {current_play}", Colors.HEADER, 'PLAY')
                continue
            
            # Detect task starts
            task_match = re.match(r'TASK \[(.*)\]', line)
            if task_match:
                current_task = task_match.group(1)
                task_start_time = time.time()
                task_stats['total'] += 1
                task_stats['tasks'].append({
                    'name': current_task,
                    'status': 'running',
                    'play': current_play,
                    'start_time': task_start_time
                })
                log(f"→ {current_task}", Colors.OKCYAN, 'TASK')
                continue
            
            # Detect task results
            if current_task:
                ok_match = re.match(r'ok: \[.*\]', line)
                changed_match = re.match(r'changed: \[.*\]', line)
                failed_match = re.match(r'failed: \[.*\]', line)
                skipped_match = re.match(r'skipping: \[.*\]', line)
                rescued_match = re.match(r'rescued: \[.*\]', line)
                ignored_match = re.match(r'\.\.\.ignoring', line)
                
                if ok_match or changed_match or failed_match or skipped_match or rescued_match or ignored_match:
                    # Update task status
                    for task in task_stats['tasks']:
                        if task['name'] == current_task and task['status'] == 'running':
                            task['status'] = 'completed'
                            task['end_time'] = time.time()
                            task['duration'] = task['end_time'] - task['start_time']
                            break
                    
                    if ok_match:
                        task_stats['completed'] += 1
                        log(f"✓ Completed: {current_task}", Colors.OKGREEN, 'SUCCESS')
                    elif changed_match:
                        task_stats['changed'] += 1
                        log(f"↻ Modified: {current_task}", Colors.WARNING, 'WARNING')
                    elif failed_match:
                        task_stats['failed'] += 1
                        log(f"✗ Failed: {current_task}", Colors.FAIL, 'ERROR')
                    elif skipped_match:
                        task_stats['skipped'] += 1
                        log(f"⊖ Skipped: {current_task}", Colors.WARNING, 'WARNING')
                    elif rescued_match:
                        task_stats['rescued'] += 1
                        log(f"⚑ Rescued: {current_task}", Colors.OKCYAN, 'INFO')
                    elif ignored_match:
                        task_stats['ignored'] += 1
                        log(f"⊘ Ignored: {current_task}", Colors.WARNING, 'WARNING')
                    
                    current_task = None
                    continue
            
            # Detect playbook recap
            if line.startswith('PLAY RECAP'):
                log("Playbook execution completed. Generating recap...", Colors.OKGREEN, 'SUCCESS')
                continue
            
            # Parse recap line
            recap_match = re.match(r'(\S+)\s*:\s*ok=(\d+)(?:\s+changed=(\d+))?(?:\s+unreachable=(\d+))?(?:\s+failed=(\d+))?(?:\s+skipped=(\d+))?(?:\s+rescued=(\d+))?(?:\s+ignored=(\d+))?', line)
            if recap_match:
                host = recap_match.group(1)
                ok = int(recap_match.group(2))
                changed = int(recap_match.group(3)) if recap_match.group(3) else 0
                unreachable = int(recap_match.group(4)) if recap_match.group(4) else 0
                failed = int(recap_match.group(5)) if recap_match.group(5) else 0
                skipped = int(recap_match.group(6)) if recap_match.group(6) else 0
                rescued = int(recap_match.group(7)) if recap_match.group(7) else 0
                ignored = int(recap_match.group(8)) if recap_match.group(8) else 0
                
                # Update task stats with recap data
                task_stats['completed'] = ok
                task_stats['changed'] = changed
                task_stats['failed'] = failed
                task_stats['skipped'] = skipped
                task_stats['rescued'] = rescued
                task_stats['ignored'] = ignored
                
                log(f"Host: {host}", Colors.OKCYAN, 'INFO')
                log(f"  - OK: {ok}, Changed: {changed}, Failed: {failed}", Colors.OKGREEN, 'SUCCESS')
                if unreachable > 0:
                    log(f"  - Unreachable: {unreachable}", Colors.FAIL, 'ERROR')
                if skipped > 0:
                    log(f"  - Skipped: {skipped}", Colors.WARNING, 'WARNING')
                if rescued > 0:
                    log(f"  - Rescued: {rescued}", Colors.OKCYAN, 'INFO')
                if ignored > 0:
                    log(f"  - Ignored: {ignored}", Colors.WARNING, 'WARNING')
                continue
            
            # Show other important lines
            if any(keyword in line.lower() for keyword in ['error', 'failed', 'warning']):
                log(line, Colors.WARNING, 'WARNING')

# Function to display task recap
def display_task_recap():
    log("\n" + "="*80, Colors.HEADER)
    log("TASK RECAP", Colors.HEADER)
    log("="*80, Colors.HEADER)
    
    # Calculate success rate
    success_rate = 0
    if task_stats['total'] > 0:
        success_rate = 100 * (task_stats['completed'] + task_stats['changed']) / task_stats['total']
    
    # Display summary
    log(f"Total Tasks: {task_stats['total']}", Colors.OKCYAN)
    log(f"Completed: {task_stats['completed']}", Colors.OKGREEN)
    log(f"Changed: {task_stats['changed']}", Colors.WARNING)
    log(f"Failed: {task_stats['failed']}", Colors.FAIL if task_stats['failed'] > 0 else Colors.OKGREEN)
    log(f"Skipped: {task_stats['skipped']}", Colors.WARNING)
    log(f"Success Rate: {success_rate:.1f}%", Colors.OKGREEN if success_rate >= 90 else Colors.WARNING)
    
    # Display task details
    if task_stats['tasks']:
        log("\nTask Details:", Colors.OKCYAN)
        for task in task_stats['tasks']:
            status_color = Colors.OKGREEN
            status_icon = "✓"
            
            if task['status'] == 'failed':
                status_color = Colors.FAIL
                status_icon = "✗"
            elif task['status'] == 'changed':
                status_color = Colors.WARNING
                status_icon = "↻"
            elif task['status'] == 'skipped':
                status_color = Colors.WARNING
                status_icon = "⊖"
            elif task['status'] == 'running':
                status_color = Colors.OKCYAN
                status_icon = "→"
            
            duration = ""
            if 'duration' in task:
                duration = f" ({task['duration']:.2f}s)"
            
            log(f"  {status_color}{status_icon} {task['name']}{duration}{Colors.ENDC}")

# Function to run shell commands with progress tracking
def run_command(command, check=True, show_progress=False):
    log(f"Executing: {' '.join(command)}", Colors.OKCYAN)
    
    if show_progress:
        stop_event = threading.Event()
        spinner_thread = threading.Thread(
            target=show_spinner,
            args=("Processing...", stop_event)
        )
        spinner_thread.daemon = True
        spinner_thread.start()
    
    try:
        result = subprocess.run(
            command, 
            check=check, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            text=True
        )
        
        if show_progress:
            stop_event.set()
            spinner_thread.join()
        
        if result.stdout:
            log(f"Output: {result.stdout.strip()}")
        if result.stderr:
            log(f"Error: {result.stderr.strip()}", Colors.FAIL, 'ERROR')
        
        return result
    except subprocess.CalledProcessError as e:
        if show_progress:
            stop_event.set()
            spinner_thread.join()
        log(f"Command failed: {e}", Colors.FAIL, 'ERROR')
        raise

# Main script execution
try:
    # Print welcome banner
    print(f"{Colors.HEADER}")
    print("╔══════════════════════════════════════════════════════════════════════════════╗")
    print("║                          Proxmox Ansible Runner                          ║")
    print("╚══════════════════════════════════════════════════════════════════════════════╝")
    print(f"{Colors.ENDC}")
    
    log('Starting Ansible environment setup', Colors.OKCYAN)

    # Check if environment is provided
    if len(sys.argv) < 2:
        log('No environment specified. Using default: dev', Colors.WARNING, 'WARNING')
        environment = 'dev'
    else:
        environment = sys.argv[1].lower()
        if environment not in ['dev', 'staging', 'prod']:
            log(f'Invalid environment: {environment}', Colors.FAIL, 'ERROR')
            show_usage()

    log(f'Target environment: {Colors.BOLD}{environment}{Colors.ENDC}', Colors.OKGREEN, 'SUCCESS')

    # Check if Python 3 is installed
    log('Checking Python 3 installation...', Colors.OKCYAN)
    run_command(['python3', '--version'])

    # Create virtual environment
    log('Creating Python virtual environment...', Colors.OKCYAN)
    run_command(['python3', '-m', 'venv', venv_dir])

    # Get paths to executables in the virtual environment
    venv_python = os.path.join(venv_dir, 'bin', 'python')
    venv_pip = os.path.join(venv_dir, 'bin', 'pip')
    venv_ansible_galaxy = os.path.join(venv_dir, 'bin', 'ansible-galaxy')
    venv_ansible_playbook = os.path.join(venv_dir, 'bin', 'ansible-playbook')
    
    # Upgrade pip
    log('Upgrading pip in virtual environment...', Colors.OKCYAN)
    run_command([venv_pip, 'install', '--upgrade', 'pip'])

    # Install required Python packages
    log('Installing required Python packages...', Colors.OKCYAN)
    run_command([venv_pip, 'install', 'ansible', 'proxmoxer', 'requests'])

    # Install Ansible collection
    log('Installing Ansible collection: community.general...', Colors.OKCYAN)
    run_command([venv_ansible_galaxy, 'collection', 'install', 'community.general'])

    # Run Ansible playbook with custom output processing
    log(f'Running Ansible playbook for environment: {Colors.BOLD}{environment}{Colors.ENDC}...', Colors.OKCYAN)
    playbook_path = os.path.join(script_dir, 'playbook.yaml')
    
    # Reset task stats
    task_stats = {
        'total': 0,
        'completed': 0,
        'changed': 0,
        'failed': 0,
        'skipped': 0,
        'rescued': 0,
        'ignored': 0,
        'tasks': []
    }
    
    # Run playbook and capture output
    process = subprocess.Popen(
        [venv_ansible_playbook, playbook_path, '--extra-vars', f'target_environment={environment}'],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,  # Line buffered
        universal_newlines=True
    )
    
    # Process output in real-time
    stop_event = threading.Event()
    output_thread = threading.Thread(
        target=process_ansible_output,
        args=(process, stop_event)
    )
    output_thread.daemon = True
    output_thread.start()
    
    # Show progress while playbook is running
    spinner_thread = threading.Thread(
        target=show_spinner,
        args=("Ansible playbook running...", stop_event)
    )
    spinner_thread.daemon = True
    spinner_thread.start()
    
    # Wait for process to complete
    return_code = process.wait()
    stop_event.set()
    output_thread.join()
    spinner_thread.join()
    
    # Display task recap
    display_task_recap()
    
    if return_code == 0:
        log(f'Ansible environment setup completed successfully for {Colors.BOLD}{environment}{Colors.ENDC}', Colors.OKGREEN, 'SUCCESS')
    else:
        log(f'Ansible playbook failed with return code {return_code}', Colors.FAIL, 'ERROR')
        sys.exit(1)

except subprocess.CalledProcessError as e:
    log(f'Error occurred: {e}', Colors.FAIL, 'ERROR')
    sys.exit(1)

except Exception as e:
    log(f'Unexpected error: {e}', Colors.FAIL, 'ERROR')
    sys.exit(1)
