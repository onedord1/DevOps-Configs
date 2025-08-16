

# Enterprise-Grade Proxmox Setup Script

This repository contains an enterprise-grade script for setting up Proxmox VM templates and user roles with permissions.

## Features

- Environment-specific configurations (dev, staging, prod)
- Configuration validation
- Secure handling of sensitive data
- Comprehensive logging
- Error handling and reporting
- Idempotent operations

## Prerequisites

- Proxmox VE installed
- `yq` command for parsing YAML files
- Root access or Proxmox admin privileges

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-org/proxmox-setup.git
   cd proxmox-setup
   ```

2. Install `yq` (YAML processor):
   ```bash
   # For Ubuntu/Debian
   sudo apt-get install yq

   # For CentOS/RHEL
   sudo yum install yq

   # Or using pip
   pip install yq
   ```

## Configuration

### Environment Variables

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` file and fill in your values:
   ```bash
   # Environment (dev, staging, prod)
   ENVIRONMENT=dev

   # Sensitive data - these should be provided securely in production
   PROXMOX_USER=root@pam
   PROXMOX_PASSWORD=your_password_here
   PROXMOX_API_TOKEN_SECRET=your_api_token_secret_here
   ```

### Configuration Files

Configuration files are stored in the `config/` directory:

- `default.yaml` - Default configuration
- `dev.yaml` - Development environment overrides
- `staging.yaml` - Staging environment overrides
- `prod.yaml` - Production environment overrides

Edit these files as needed for your environment. The environment-specific files override the default values.

## Usage

Run the script with the desired environment:

```bash
# For development environment
./scripts/proxmox-setup.sh --env dev

# For staging environment
./scripts/proxmox-setup.sh --env staging

# For production environment
./scripts/proxmox-setup.sh --env prod
```

You can also specify a custom configuration directory:

```bash
./scripts/proxmox-setup.sh --env prod --config-dir /path/to/config
```

## Security Considerations

1. **Sensitive Data**: Store sensitive data in environment variables or use a secrets management system.

2. **File Permissions**: Ensure configuration files have appropriate permissions:
   ```bash
   chmod 600 .env
   chmod 644 config/*.yaml
   ```

3. **Audit Trail**: The script logs all actions to both console and file (if configured).

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure you're running the script as root or with Proxmox admin privileges.

2. **Command Not Found**: Install all required commands (`yq`, `qm`, `pveum`, `wget`).

3. **Configuration Validation Failed**: Check your configuration files for errors.

### Logs

Check the log file for detailed information:
```bash
tail -f ../log/proxmox-setup.log
```