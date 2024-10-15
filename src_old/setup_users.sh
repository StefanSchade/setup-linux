#!/bin/bash

# Define the users who need configuration from users.txt
USERS=$(cat users.txt)

# Function to install packages from a file (System-Level)
install_packages() {
    local file=$1
    if [[-f $file ]]; then
        echo "Installing packages from $file..."
        xargs -a "$file" sudo apt install -y
    else
        echo "Package list $file not found!"
    fi
}

# Function to append to .bashrc if not allready present
append_to_bashrc() {
    local user=$1
    local line=$2
    local bashrc_file="/home/$user/.bashrc"

    # Check if the line already exists
    if ! grep -Fxq "$line" $bashrc_file; then
         sudo bash -c "echo 'line' >> $bashrc_file" 
    fi
}

# Function to configure each user (User-level)
configure_user() {
    local user=$1
    echo "Configuring settings for $user..."

    # Add user to the docker group (if available)
    sudo usermod -aG docker $user

    # Create neovim config dir for user
    sudo -u $user mkdir -p /home/$user/.config/nvim

    # Add custom bash aliasses and environment variables, inf not already set
    append_to_bashrc $user 'export PATH=$HOME/.cargo/bin:$PATH'
    append_to_bashrc $user 'alias nvim="nvim"'
    append_to_bashrc $user 'alias ll="ls -lah"'
    append_to_bashrc $user 'alias gs="git status"'
}

# System level: update and upgrade system
sudo apt update && sudo apt upgrade -y

# System level: Install office related packages
install_packages "packages/office.txt"

# System level: install Rust
install_packages "packages/programming_rust.txt"

# System level: install general programming env
install_packages "packages/programming_general.txt" 

# Config users
for user in $USERS; do
    configure_user $user
done

# System level: install npm for node
sudo npm install -g typescript yarn

# System level: Setup docker to start automatically
sudo systemctl enable docker

 
