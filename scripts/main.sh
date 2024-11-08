#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Function to display usage
usage() {
    echo "Usage: $0"
    exit 1
}

# Function to handle cleanup on interruption
cleanup() {
    echo "Script interrupted. Performing cleanup..."
    exit 1
}

# Trap SIGINT and SIGTERM to execute the cleanup function
trap cleanup SIGINT SIGTERM

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it and retry."
        exit 1
    fi
}

# Function to detect the available package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    else
        echo "unsupported"
    fi
}

# Function to wait for package manager locks to be released
wait_for_package_manager() {
    local pm="$1"
    echo "Checking for active package operations..."
    case "$pm" in
        apt)
            while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
                  sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1 || \
                  sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
                echo "Another package process is running. Waiting..."
                sleep 5
            done
            ;;
        pacman)
            while sudo fuser /var/lib/pacman/db.lck >/dev/null 2>&1; do
                echo "Another pacman process is running. Waiting..."
                sleep 5
            done
            ;;
        dnf)
            while sudo fuser /var/cache/dnf/ >/dev/null 2>&1; do
                echo "Another dnf process is running. Waiting..."
                sleep 5
            done
            ;;
        *)
            echo "Unsupported package manager."
            exit 1
            ;;
    esac
    echo "No active package operations detected."
}

# Function to install dependencies based on the detected package manager
install_dependencies() {
    local pm="$1"
    echo "Installing script dependencies using $pm..."
    case "$pm" in
        apt)
            sudo apt-get update
            sudo apt-get install -y curl unzip git
            ;;
        pacman)
            sudo pacman -Syu --noconfirm curl unzip git
            ;;
        dnf)
            sudo dnf install -y curl unzip git
            ;;
        *)
            echo "Unsupported package manager. Please install curl, unzip, and git manually."
            exit 1
            ;;
    esac
}

# Function to perform autoremove based on the detected package manager
perform_autoremove() {
    local pm="$1"
    echo "Do you want to remove unnecessary packages? [y/N]"
    read -r response
    case "$response" in
        [Yy]* )
            echo "Removing unnecessary packages using $pm..."
            case "$pm" in
                apt)
                    sudo apt autoremove -y
                    ;;
                pacman)
                    orphans=$(pacman -Qdtq)
                    if [ -n "$orphans" ]; then
                        sudo pacman -Rns --noconfirm $orphans
                    else
                        echo "No orphaned packages found."
                    fi
                    ;;
                dnf)
                    sudo dnf autoremove -y
                    ;;
                *)
                    echo "Unsupported package manager."
                    ;;
            esac
            echo "Unnecessary packages removed successfully."
            ;;
        * )
            echo "Skipping removal of unnecessary packages."
            ;;
    esac
}

# Function to run user-level scripts
run_user_tasks() {
    echo "Select a user task:"
    select task in "User Creation" "Setup Keymap" "Setup Git" "Setup SSH" "Exit"; do
        case $REPLY in
            1) bash ./scripts/user/create_users.sh "$INPUT_DIR/users" ;;
            2) bash ./scripts/user/setup_keymaps.sh "$INPUT_DIR/keyboard" ;;
            3) bash ./scripts/user/setup_git.sh "$INPUT_DIR/users" ;;
            4) bash ./scripts/user/setup_ssh.sh "$INPUT_DIR/users" ;;
            5) break ;;
            *) echo "Invalid option";;
        esac
    done
}

# Function to run system-level scripts
run_system_tasks() {
    echo "Select a system task:"
    select task in "Install Packages" "Uninstall Packages" "Update System" "Extract System Info" "Exit"; do
        case $REPLY in
            1) bash ./scripts/system/install_packages.sh "$INPUT_DIR/packages" ;;
            2) bash ./scripts/system/uninstall_packages.sh "$INPUT_DIR/packages" ;;
            3)
                if [ "$PACKAGE_MANAGER" = "apt" ]; then
                    sudo apt-get update && sudo apt-get upgrade -y
                elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
                    sudo pacman -Syu --noconfirm
                elif [ "$PACKAGE_MANAGER" = "dnf" ]; then
                    sudo dnf upgrade -y
                fi
                ;;
            4) bash ./scripts/system/extract_system_info.sh "$OUTPUT_DIR" ;;
            5) break ;;
            *) echo "Invalid option";;
        esac
    done
}

# Function to run hybrid scripts
run_hybrid_tasks() {
    echo "Select a hybrid task (system-wide or user-specific):"
    select task in "Fonts Setup" "Desktop Icons" "Exit"; do
        case $REPLY in
            1) bash ./scripts/hybrid/fonts_setup.sh "$INPUT_DIR/fonts" ;;
            2) bash ./scripts/hybrid/desktop_icons.sh "$INPUT_DIR/desktop_icons" ;;
            3) break ;;
            *) echo "Invalid option";;
        esac
    done
}

# Function to check if running as root for system-level tasks
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Please run this script as root for system-level tasks."
        exit 1
    fi
}

# Define the input configuration directory
INPUT_DIR="./config"

# Define the output directory for system info
OUTPUT_DIR="./system_reports"

# Detect the package manager
PACKAGE_MANAGER=$(detect_package_manager)

if [ "$PACKAGE_MANAGER" = "unsupported" ]; then
    echo "No supported package manager found (apt, pacman, dnf). Exiting."
    exit 1
fi

# Wait for any ongoing package operations to finish
wait_for_package_manager "$PACKAGE_MANAGER"

# Install Script dependencies
install_dependencies "$PACKAGE_MANAGER"

# Perform autoremove if the user chooses to
perform_autoremove "$PACKAGE_MANAGER"

# Remove traps after critical operations
trap - SIGINT SIGTERM

echo "Dependencies installed successfully."

# Main menu function
main_menu() {
    echo "Main Menu - Select a category:"
    select category in "User-specific tasks" "System-wide tasks" "Hybrid Tasks" "Exit"; do
        case $REPLY in
            1) run_user_tasks ;;
            2)
                check_root
                run_system_tasks
                ;;
            3)
                check_root
                run_hybrid_tasks
                ;;
            4) exit 0 ;;
            *) echo "Invalid option";;
        esac
    done
}

# Start the main menu
main_menu

