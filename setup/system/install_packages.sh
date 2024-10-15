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

# Install packages from apt
if [ -f "$apt_file" ]; then
  echo "Installing packages with apt..."
  clean_lines < "$apt_file" | while IFS= read -r package; do
    echo "Installing $package..."
    sudo apt-get update && sudo apt-get install -y "$package"
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
    wget "$deb_url" -O "$deb_file"
    echo "Installing $deb_file..."
    sudo dpkg -i "$deb_file"
    echo "Removing $deb_file..."
    rm "$deb_file"
  done

  # Clean up temporary directory
  rm -rf "$temp_dir"
fi

echo "Package installation completed."

