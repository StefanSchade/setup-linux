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

# Check if required files exist
if [ ! -f "$apt_file" ] && [ ! -f "$deb_file" ]; then
  echo "Error: No valid configuration files found. Expecting 'packages_apt.txt' or 'packages_deb.txt'."
  exit 1
fi

# Install packages from apt
if [ -f "$apt_file" ]; then
  echo "Installing packages with apt..."
  while IFS= read -r package; do
    echo "Installing $package..."
    sudo apt-get update && sudo apt-get install -y "$package"
  done < "$apt_file"
fi

# Install .deb packages
if [ -f "$deb_file" ]; then
  temp_dir="$config_dir/tmp_$(date +%s)"
  mkdir -p "$temp_dir"

  echo "Installing .deb packages..."
  while IFS= read -r deb_url; do
    deb_file="$temp_dir/$(basename "$deb_url")"
    echo "Downloading $deb_url..."
    wget "$deb_url" -O "$deb_file"
    echo "Installing $deb_file..."
    sudo dpkg -i "$deb_file"
    echo "Removing $deb_file..."
    rm "$deb_file"
  done < "$deb_file"

  # Clean up temporary directory
  rm -rf "$temp_dir"
fi

echo "Package installation completed."

