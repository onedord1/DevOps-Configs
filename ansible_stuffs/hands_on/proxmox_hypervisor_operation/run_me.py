import os
import subprocess
import sys
from datetime import datetime

# Define directories
script_dir = os.path.dirname(os.path.realpath(__file__))
venv_dir = os.path.join(script_dir, 'ansible-venv')
logs_dir = os.path.join(script_dir, 'logs')
log_file = os.path.join(logs_dir, f'ansible_setup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

# Ensure logs directory exists
os.makedirs(logs_dir, exist_ok=True)

# Function to log messages
def log(message):
    print(message)
    with open(log_file, 'a') as f:
        f.write(f'{datetime.now().strftime("%Y-%m-%d %H:%M:%S")} - {message}\n')

# Function to run shell commands
def run_command(command, check=True):
    log(f'Running command: {" ".join(command)}')
    result = subprocess.run(command, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    log(f'Command output: {result.stdout.decode()}')
    if result.stderr:
        log(f'Command error: {result.stderr.decode()}')
    return result

# Main script execution
try:
    log('Starting Ansible environment setup')

    # Check if Python 3 is installed
    log('Checking if Python 3 is installed...')
    run_command(['python3', '--version'])

    # Install Python venv module if not present
    log('Installing python3-venv...')
    run_command(['sudo', 'apt', 'install', '-y', 'python3-venv'])

    # Create virtual environment
    log('Creating Python virtual environment...')
    run_command(['python3', '-m', 'venv', venv_dir])

    # Activate virtual environment
    activate_script = os.path.join(venv_dir, 'bin', 'activate')
    if not os.path.exists(activate_script):
        raise FileNotFoundError(f'Activation script not found: {activate_script}')
    log(f'Activating virtual environment: {activate_script}')
    subprocess.run(f'source {activate_script} && pip install --upgrade pip', shell=True, check=True)

    # Install required Python packages
    log('Installing required Python packages...')
    subprocess.run(f'source {activate_script} && pip install ansible proxmoxer requests', shell=True, check=True)

    # Install Ansible collection
    log('Installing Ansible collection: community.general')
    subprocess.run(f'source {activate_script} && ansible-galaxy collection install community.general', shell=True, check=True)

    # Run Ansible playbook
    log('Running Ansible playbook...')
    playbook_path = os.path.join(script_dir, 'playbook.yml')
    subprocess.run(f'source {activate_script} && ansible-playbook {playbook_path}', shell=True, check=True)

    log('Ansible environment setup completed successfully')

except subprocess.CalledProcessError as e:
    log(f'Error occurred: {e}')
    sys.exit(1)

except Exception as e:
    log(f'Unexpected error: {e}')
    sys.exit(1)
