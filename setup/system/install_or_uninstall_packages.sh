#!/bin/bash
# Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

# Check if directory argument is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

config_dir="$1"
apt_file="$config_dir/packages_apt.txt"
deb_file="$config_dir/packages_deb.txt"

# Function to clean lines by removing inline comments and skipping empty/commented lines
clean_lines() {
  while IFS= read -r line || [ -n "$line" ]; do
    # Remove inline comments and trim leading/trailing whitespace
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)

    # Skip empty lines and commented lines
    if [ -n "$clean_line" ]; then
      echo "$clean_line"
    fi
  done
}

# Prompt the user for install or uninstall
echo "Would you like to (I)nstall or (U)ninstall packages?"
read -p "(I/U): " choice

if [[ "$choice" =~ ^[Ii]$ ]]; then
  echo "Proceeding with package installation..."

  # Install packages from apt
  if [ -f "$apt_file" ]; then
    echo "Installing packages with apt..."
    clean_lines < "$apt_file" | while IFS= read -r package; do
      if sudo apt-get update && sudo apt-get install -y "$package"; then
        echo "$package installed successfully."
      else
        echo "Failed to install $package. Skipping..."
      fi
    done
  fi

  # Install .deb packages
  if [ -f "$deb_file" ]; then
    temp_dir="$config_dir/tmp_$(date +%s)"
    mkdir -p "$temp_dir"

    echo "Installing .deb packages..."
    clean_lines < "$deb_file" | while IFS= read -r deb_url; do
      deb_file="$temp_dir/$(basename "$deb_url")"
      echo "Downloading $deb_url..."
      if wget "$deb_url" -O "$deb_file"; then
        echo "Installing $deb_file..."
        if sudo dpkg -i "$deb_file"; then
          echo "$deb_file installed successfully."
        else
          echo "Failed to install $deb_file. Fixing dependencies..."
          sudo apt-get install -f -y  # Automatically fix dependencies
        fi
        echo "Removing $deb_file..."
        rm "$deb_file"
      else
        echo "Failed to download $deb_url. Skipping..."
      fi
    done

    # Clean up temporary directory
    rm -rf "$temp_dir"
  fi

  echo "Package installation completed."

elif [[ "$choice" =~ ^[Uu]$ ]]; then
  echo "Proceeding with package uninstallation..."

  # Uninstall packages from apt
  if [ -f "$apt_file" ]; then
    echo "Uninstalling packages with apt..."
    clean_lines < "$apt_file" | while IFS= read -r package; do
      echo "Uninstalling $package..."
      sudo apt-get remove -y "$package" || echo "Package $package not found. Skipping..."
    done
  fi

  # Uninstall .deb packages (handle as apt packages)
  if [ -f "$deb_file" ]; then
    echo "Uninstalling .deb packages..."
    clean_lines < "$deb_file" | while IFS= read -r deb_url; do
      package_name=$(basename "$deb_url" .deb)
      echo "Uninstalling $package_name..."
      sudo apt-get remove -y "$package_name" || echo "Package $package_name not found. Skipping..."
    done
  fi

  echo "Package uninstallation completed."

else
  echo "Invalid option. Please choose 'I' for install or 'U' for uninstall."
  exit 1
fi

