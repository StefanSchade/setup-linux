#!/bin/bash
#
# This script can either install the fonts per user or system wide (therefore
# we consider it as a hybrid task) 


# Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

# Check if directory argument is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

config_dir="$1"
font_links_file="$config_dir/font_download_links.txt"
users_file="$config_dir/users.txt"
temp_dir="$config_dir/tmp_$(date +%s)"

# Check if required files exist
if [ ! -f "$font_links_file" ]; then
  echo "Error: '$font_links_file' not found. Please provide the font_download_links.txt file."
  exit 1
fi

if [ ! -f "$users_file" ]; then
  echo "Error: '$users_file' not found. Please provide the users.txt file."
  exit 1
fi

# Create a temporary directory for font extraction
mkdir -p "$temp_dir"

# Download and extract fonts
while IFS= read -r link; do
  echo "Downloading $link..."
  zip_file="$temp_dir/$(basename "$link")"
  curl -L "$link" -o "$zip_file"
  unzip -o -q "$zip_file" -d "$temp_dir"
  rm "$zip_file"
done < "$font_links_file"

# Prompt for system-wide or user-specific installation
echo "Do you want to install the fonts system-wide or for specific users?"
read -p "Enter 'system' for system-wide or 'user' for user-specific: " install_type

if [ "$install_type" = "system" ]; then
  echo "Installing fonts system-wide..."
  sudo cp "$temp_dir"/*.{ttf,otf} /usr/share/fonts/ || true
  sudo fc-cache -fv
else
  while IFS= read -r user; do
    echo "Installing fonts for user: $user..."
    user_font_dir="/home/$user/.local/share/fonts"
    mkdir -p "$user_font_dir"
    cp "$temp_dir"/*.{ttf,otf} "$user_font_dir" || true
    sudo -u "$user" fc-cache -fv "$user_font_dir"
  done < "$users_file"
fi

# refresh the font cache for the current user
fc-cache -fv ~/.local/share/fonts

# Clean up temporary directory
rm -rf "$temp_dir"
echo "Font installation completed."

