

# Kubeconfig Manager

A robust and efficient shell script for managing multiple Kubernetes kubeconfig files with fzf integration. This tool simplifies the process of switching between different Kubernetes clusters by providing an intuitive interface for selecting and managing kubeconfig files.

## Features

- **Interactive Selection**: Use fzf to fuzzy-search and select kubeconfig files from your ~/.kube directory
- **Multiple File Extensions**: Support for .yaml, .yml, .config, .dev, .qa, .prod, and .txt file extensions
- **Create New Configs**: Easily create new kubeconfig files with a template using vim
- **Backup Management**: Optional backup functionality to preserve your current configuration
- **File Validation**: Automatic validation of kubeconfig files to ensure they meet Kubernetes requirements
- **Dependency Installation**: Built-in --init option to install all required dependencies
- **Beautiful Output**: Color-coded messages for success, errors, warnings, and information
- **Current Context Display**: Shows your current Kubernetes context and cluster information

## Prerequisites

The script requires the following dependencies:
- fzf (command-line fuzzy finder)
- vim (text editor)
- kubectl (Kubernetes command-line tool)
- python3-yaml (for YAML validation)

All dependencies can be automatically installed using the --init option.

## Installation

1. Save the script as `clusters` in your preferred location
2. Make it executable:
   ```
   chmod +x clusters
   ```
3. Add an alias to your systemwide:
   ```
   cp clusters /usr/local/bin/clusters
   ```

## Usage

### Interactive Mode (Main Functionality)

Run the script without any arguments to enter interactive mode:
```
clusters
```

This will display an fzf interface showing all available kubeconfig files in your ~/.kube directory. You can fuzzy-search by typing part of the filename and press Enter to select a file. The selected file will be copied to ~/.kube/config, making it your active kubeconfig.

### Command Line Options

- **Create a new config file**:
  ```
  clusters -a <name>
  ```
  This opens vim with a kubeconfig template. The file is only saved if you make changes and save in vim.

- **List all available config files**:
  ```
  clusters -l
  ```

- **Create a backup of your current config**:
  ```
  clusters -b
  ```

- **Restore config from backup**:
  ```
  clusters -r <backup-file>
  ```

- **Validate a kubeconfig file**:
  ```
  clusters -v <file>
  ```

- **Show current context information**:
  ```
  clusters -c
  ```

- **Install required dependencies**:
  ```
  clusters --init
  ```

- **Show help**:
  ```
  clusters -h
  ```

## File Management

The script intelligently handles file creation and editing:

- When creating a new config file, a temporary file is used with a kubeconfig template
- The file is only saved to your ~/.kube directory if you make changes and save in vim
- If you quit vim without saving (using :q!), no file is created
- The script validates all kubeconfig files to ensure they meet Kubernetes requirements

## Supported File Extensions

The script recognizes kubeconfig files with the following extensions:
- .yaml
- .yml
- .config
- .dev
- .qa
- .prod
- .txt

## Backup System

The script includes a backup system that:
- Creates timestamped backups of your current config
- Maintains a configurable number of recent backups (default: 5)
- Automatically cleans up old backups
- Allows restoration from any backup file

## Error Handling

The script includes comprehensive error handling:
- Validates kubeconfig files before switching
- Checks for required dependencies and provides installation instructions
- Provides clear, color-coded error messages
- Handles file conflicts and prompts for user confirmation

## User Experience

The script is designed with user experience in mind:
- Intuitive fzf interface for file selection
- Preview of file contents during selection
- Color-coded output for different message types
- Clear success and error messages
- Helpful hints and suggestions throughout the process

## Compatibility

The script is compatible with:
- Linux systems (Ubuntu, Debian, CentOS, etc.)
- macOS
- Bash and Zsh shells

## Support

For issues, questions, or contributions, please refer to the script's help functionality:
```
clusters -h
```

This will display detailed usage information and all available options.