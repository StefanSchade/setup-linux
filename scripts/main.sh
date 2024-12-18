#!/bin/bash

set -euo pipefail
set -m
IFS=$'\n\t'

# Function to handle cleanup on interruption
cleanup() {
    echo "Script interrupted. Performing cleanup..."
    # Add any additional cleanup commands here if necessary
    exit 1
}

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

# Function to run user-level scripts
run_user_tasks() {
    echo "Select a user task:"
    select task in "User Creation" "Setup Keymap" "Setup Git" "Setup SSH" "Exit"; do
        case $REPLY in
            1) bash ./scripts/user/create_users.sh "$INPUT_DIR/users"; break ;;
            2) bash ./scripts/user/setup_keymaps.sh "$INPUT_DIR/keyboard"; break ;;
            3) bash ./scripts/user/setup_git.sh "$INPUT_DIR/users"; break ;;
            4) bash ./scripts/user/setup_ssh.sh "$INPUT_DIR/users"; break ;;
            5) break ;;
            *) 
                echo "Invalid option. Please select a valid number."
                break
                ;;
        esac
    done
}

# Function to run system-level scripts
run_system_tasks() {
    echo "Select a system task:"
    select task in "Install Packages" "Uninstall Packages" "Update System" "Extract System Info" "Exit"; do
        case $REPLY in
            1) bash ./scripts/system/install_packages.sh "$INPUT_DIR/packages"; break ;;
            2) bash ./scripts/system/uninstall_packages.sh "$INPUT_DIR/packages"; break ;;
            3)
                if [ "$PACKAGE_MANAGER" = "apt" ]; then
                    sudo apt-get update && sudo apt-get upgrade -y
                elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
                    sudo pacman -Syu --noconfirm
                elif [ "$PACKAGE_MANAGER" = "dnf" ]; then
                    sudo dnf upgrade -y
                fi
                break
                ;;
            4) bash ./scripts/system/extract_system_info.sh "$OUTPUT_DIR"; break ;;
            5) break ;;
            *) 
                echo "Invalid option. Please select a valid number."
                break
                ;;
        esac
    done
}

# Function to run hybrid scripts
run_hybrid_tasks() {
    echo "Select a hybrid task (system-wide or user-specific):"
    select task in "Fonts Setup" "Desktop Icons" "Exit"; do
        case $REPLY in
            1) bash ./scripts/hybrid/fonts_setup.sh "$INPUT_DIR/fonts"; break ;;
            2) bash ./scripts/hybrid/desktop_icons.sh "$INPUT_DIR/desktop_icons"; break ;;
            3) break ;;
            *) 
                echo "Invalid option. Please select a valid number."
                break
                ;;
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

# Main menu function
main_menu() {
    while true; do
        echo "Main Menu - Select a category:"
        select category in "User-specific tasks" "System-wide tasks" "Hybrid Tasks" "Exit"; do
            case $REPLY in
                1) run_user_tasks; break ;;
                2)
                    check_root
                    run_system_tasks
                    break
                    ;;
                3)
                    check_root
                    run_hybrid_tasks
                    break
                    ;;
                4) 
                    echo "Exiting..."
                    exit 0 
                    ;;
                *) 
                    echo "Invalid option. Please select a valid number."
                    break
                    ;;
            esac
        done
    done
}

# Trap SIGINT and SIGTERM to execute the cleanup function
trap cleanup SIGINT SIGTERM

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

echo "Dependencies installed successfully."

# Remove traps after critical operations
trap - SIGINT SIGTERM

# Start the main menu
main_menu
