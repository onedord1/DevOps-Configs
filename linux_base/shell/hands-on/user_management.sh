#!/bin/bash

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
    fi
}

# Function to create a new user
create_user() {
    read -p "Enter username to create: " username
        if id "$username" &>/dev/null; then
            echo "User '$username' already exists."
            return
        fi
    read -s -p "Enter password for $username: " password
    echo
        useradd -m -s /bin/bash "$username"
        echo "$username:$password" | chpasswd
        echo "User '$username' created successfully."
        read -p "Add user to a group? (y/n): " add_group

        if [[ "$add_group" == "y" ]]; then
        read -p "Enter group name: " groupname
            if grep -q "^$groupname:" /etc/group; then
                usermod -aG "$groupname" "$username"
            echo "User '$username' added to group '$groupname'."
            else
            echo "Group '$groupname' does not exist."
            fi
        fi
}

# Function to delete a user
delete_user() {
    read -p "Enter username to delete: " username
        if ! id "$username" &>/dev/null; then
            echo "User '$username' does not exist."
            return
        fi
    read -p "Are you sure you want to delete user '$username'? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        userdel -r "$username"
    echo "User '$username' deleted successfully."
    else
        echo "User deletion aborted."
    fi
}

# Function to list all users
list_users() {
    echo "Listing all system users:"
    awk -F':' '{ print $1 }' /etc/passwd
}

# Function to lock a user
lock_user() {
    read -p "Enter username to lock: " username
    if id "$username" &>/dev/null; then
        passwd -l "$username"
        echo "User '$username' has been locked."
    else
        echo "User '$username' does not exist."
    fi
}

# Function to unlock a user
unlock_user() {
    read -p "Enter username to unlock: " username
    if id "$username" &>/dev/null; then
        passwd -u "$username"
        echo "User '$username' has been unlocked."
    else
        echo "User '$username' does not exist."
    fi
}

# Function to show menu
show_menu() {
    echo "--------------------------------------"
    echo " Ubuntu User Management Script "
    echo "--------------------------------------"
    echo "1) Create a new user"
    echo "2) Delete a user"
    echo "3) List all users"
    echo "4) Lock a user"
    echo "5) Unlock a user"
    echo "6) Exit"
    echo "--------------------------------------"
}

# Main script execution
check_root

while true; do
    show_menu
    read -p "Choose an option: " choice
    case $choice in
    1) create_user ;;
    2) delete_user ;;
    3) list_users ;;
    4) lock_user ;;
    5) unlock_user ;;
    6) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid option. Please select a valid choice." ;;
    esac
done