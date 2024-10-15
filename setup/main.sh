#!/bin/bash

# Centralized input directory
INPUT_DIR=../config

# Install Script dependencies

sudo apt-get update
sudo apt-get install -y curl unzip 

# Function to run user-level scripts=
run_user_tasks() {
    echo "Select a user task:"
    select task in "Keyboard Setup" "Git Setup" "Exit"; do
        case $REPLY in
            1) bash ~/linux-setup/scripts/user/setup_keyboard.sh "$INPUT_DIR/user-configs" ;;
            2) bash ~/linux-setup/scripts/user/setup_git.sh "$INPUT_DIR/user-configs" ;;
            3) break ;;
            *) echo "Invalid option";;
        esac
    done
}


# Function to run system-level scripts
run_system_tasks() {
    echo "Select a system task:"
    select task in "Install Packages" "Update System" "Exit"; do
        case $REPLY in
            1) bash ./system/install_packages.sh "$INPUT_DIR" ;;
            2) bash ~/linux-setup/scripts/system/update_system.sh "$INPUT_DIR/system-configs" ;;
            3) break ;;
            *) echo "Invalid option";;
        esac
    done
}


# Function to run hybrid scripts
run_hybrid_tasks() {
   echo "Select a hybrit task (you will be prompted wether to perform it user specific or system wide):"
    select task in "fonts setup" "desktop icons" "Exit"; do
        case $REPLY in
            1) bash ./hybrid/fonts_setup.sh "$INPUT_DIR" ;;
            1) bash ./hybrid/desktop_icons.sh "$INPUT_DIR" ;;
            2) break ;;
            *) echo "Invalid option";;
        esac
    done
}


# Check if we are running as root
current_user=$(whoami)
echo "The current user is $current_user" | tee -a $results_file
if [[ $current_user != "root" ]]; then
    echo "Must be root user. Try 'su -'" | tee -a $results_file
    exit 1
fi

# Main menu
echo "Main Menu - Select a category:"
select category in "User-specific tasks" "System-wide tasks" "Hybrid Tasks" "Exit"; do
    case $REPLY in
        1) run_user_tasks ;;
        2) run_system_tasks ;;
        3) run_hybrid_tasks ;;
        4) exit 0 ;;
        *) echo "Invalid option";;
    esac
done

