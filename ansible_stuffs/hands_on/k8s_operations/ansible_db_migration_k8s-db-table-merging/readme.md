

# Database Migration Automation with Ansible

This project provides an automated solution for migrating specific tables from a source database to a target database using Ansible. The solution supports both PostgreSQL and MySQL databases and includes optional steps for scaling backend replicas and checking storage availability.

## Overview

The automation performs the following steps:
1. Scale down source backend replicas (optional)
2. Backup specified tables from the source database
3. Scale up source backend replicas (optional)
4. Scale down target backend replicas
5. Check Longhorn node storage capacity
6. Restore source tables to the target database
7. Scale up the target backend replicas
8. Check the target application health after migration

## Directory Structure

```
.
├── ansible.cfg                 # Ansible configuration file
├── dumps/                      # Directory for storing database dumps
├── image.png                   # Project diagram/image
├── inventories/
│   └── var.ini                 # Configuration variables
├── kubeconfig/
│   └── kubeconfig              # Kubernetes configuration
├── logs/                       # Directory for log files
├── playbooks/
│   └── main.yaml               # Main playbook
├── readme.md                   # This file
├── roles/
│   ├── common-scale/
│   │   └── tasks/
│   │       ├── replica-down.yaml    # Scale down replicas
│   │       └── replica-up.yaml      # Scale up replicas
│   ├── longhorn-storage-check/
│   │   └── tasks/
│   │       └── storage-availability.yaml  # Check storage capacity
│   ├── mysql/
│   │   └── tasks/
│   │       ├── clean-target-db.yaml      # Clean target database
│   │       ├── create-source-db-dump.yaml # Create source database dump
│   │       ├── create-target-db-dump.yaml # Create target database dump
│   │       └── restore-db.yaml           # Restore database
│   └── postgres/
│       └── tasks/
│           ├── backup-source-tables.yaml          # Backup source tables
│           ├── clean-target-db.yaml              # Clean target database
│           ├── create-source-db-dump.yaml        # Create source database dump
│           ├── create-target-db-dump.yaml        # Create target database dump
│           ├── restore-db.yaml                   # Restore database
│           └── restore-source-tables-into-target.yaml  # Restore tables to target
└── run_me_to_start.sh         # Script to start the migration
```

## Prerequisites

Before running the migration, ensure you have:

- Ansible installed on the control node
- Access to both source and target databases
- Kubernetes cluster access (if using replica scaling)
- Proper permissions to perform database operations
- Sufficient storage space for database dumps

## Configuration

All configuration parameters are defined in the `inventories/var.ini` file must modify in some cases:

```ini
[local]
localhost ansible_connection=local

[local:vars]
# Database type (postgres or mysql)
db_type=postgres

# Source database configuration
source_namespace=cortezadevops-dev-mhoi-ns
source_backend_deployment=cortezapod
source_kubeconfig=../kubeconfig/kubeconfig
FROM_DB_NAME=corteza
FROM_DB_USER=rootuser
FROM_DB_HOST=172.17.17.160
FROM_DB_PORT=5432
FROM_DB_PASSWORD=superAdmin

# Target database configuration
target_namespace=cortezadevops-qa-ofzt-ns
target_backend_deployment=cortezapod
target_replica_count=1
target_kubeconfig=../kubeconfig/kubeconfig
TO_DB_NAME=corteza
TO_DB_USER=rootuser
TO_DB_HOST=172.17.17.163
TO_DB_PORT=5432
TO_DB_PASSWORD=superAdmin

# Tables to migrate
TABLES=compose_record,credentials,users,role_members,compose_attachment

# Longhorn storage configuration
longhorn_node=172.17.17.155
longhorn_port=32657

# Application health check URL
app_health_url=http://172.17.17.163/health/
```

## Migration Steps Explained

### 1. Scale Down Source Backend Replicas (Optional)
- Reduces the source backend replica count to 0
- Minimizes changes to the database during backup
- Controlled by `common-scale/replica-down.yaml`

### 2. Backup Tables from Source Database
- Creates individual dumps for each specified table
- Uses PostgreSQL's `pg_dump` or MySQL's `mysqldump` with custom format
- Controlled by `postgres/tasks/backup-source-tables.yaml` or `mysql/tasks/create-source-db-dump.yaml`

### 3. Scale Up Source Backend Replicas (Optional)
- Restores the source backend replica count to its original value
- Controlled by `common-scale/replica-up.yaml`

### 4. Scale Down Target Backend Replicas
- Reduces the target backend replica count to 0
- Prevents conflicts during database restoration
- Controlled by `common-scale/replica-down.yaml`

### 5. Check Longhorn Node Storage Capacity
- Verifies that sufficient storage is available for the migration
- Controlled by `longhorn-storage-check/storage-availability.yaml`

### 6. Restore Source Tables to Target Database
- Restores each table dump to the target database
- Uses PostgreSQL's `pg_restore` or MySQL's `mysql` command
- Controlled by `postgres/tasks/restore-source-tables-into-target.yaml` or `mysql/tasks/restore-db.yaml`

### 7. Scale Up Target Backend Replicas
- Restores the target backend replica count to its configured value
- Controlled by `common-scale/replica-up.yaml`

### 8. Check Target Application Health
- Verifies that the application is functioning correctly after the migration
- Checks the health endpoint specified in the configuration
- Controlled by health check tasks in the main playbook

## How to Run

To start the migration process, simply execute the provided script:

```bash
./run_me_to_start.sh
```

This script will:
1. Set up the necessary environment
2. Run the Ansible playbook
3. Generate logs in the `logs/` directory

## Troubleshooting

### Common Issues

1. **Undefined Variable Errors**
   - Ensure all required variables are defined in `inventories/var.ini`
   - Check for typos in variable names

2. **Database Connection Errors**
   - Verify database credentials and connectivity
   - Check firewall settings between the control node and databases

3. **Permission Errors**
   - Ensure the Ansible user has sufficient permissions
   - Check file permissions for the kubeconfig file

4. **Storage Issues**
   - Verify that there is enough storage space for the dumps
   - Check Longhorn node availability and capacity

### Log Files

All migration logs are stored in the `logs/` directory with timestamps:
- `ansible_migration_YYYYMMDD_HHMMSS.log`

### Debug Mode

To run the playbook with verbose output for debugging:

```bash
ansible-playbook -i inventories/var.ini playbooks/main.yaml -vvv
```

## Customization

### Adding New Tables

To migrate additional tables:
1. Edit the `TABLES` variable in `inventories/var.ini`
2. Separate table names with commas

### Supporting New Database Types

To add support for additional database types:
1. Create a new role directory under `roles/`
2. Implement the necessary task files following the existing pattern
3. Update the main playbook to include the new database type
