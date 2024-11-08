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
icon_config_file="$config_dir/desktop_icon_config.txt"

# Check if the required file exists
if [ ! -f "$icon_config_file" ]; then
  echo "Error: '$icon_config_file' not found. Please provide a valid desktop_icon_config.txt file."
  exit 1
fi

# Create desktop icons based on configuration
while IFS=',' read -r name comment exec icon terminal type categories user_or_system; do
  desktop_entry="[Desktop Entry]
Name=$name
Comment=$comment
Exec=$exec
Icon=$icon
Terminal=$terminal
Type=$type
Categories=$categories"

  # Install per user or system-wide
  if [ "$user_or_system" = "user" ]; then
    user_desktop_dir="$HOME/.local/share/applications"
    echo "Creating desktop icon for user: $name"
    mkdir -p "$user_desktop_dir"
    desktop_file="$user_desktop_dir/$name.desktop"
    echo "$desktop_entry" > "$desktop_file"
    chmod +x "$desktop_file"
  elif [ "$user_or_system" = "system" ]; then
    system_desktop_dir="/usr/share/applications"
    echo "Creating system-wide desktop icon for: $name"
    sudo mkdir -p "$system_desktop_dir"
    desktop_file="$system_desktop_dir/$name.desktop"
    echo "$desktop_entry" | sudo tee "$desktop_file" > /dev/null
    sudo chmod +x "$desktop_file"
  else
    echo "Invalid value for user_or_system: $user_or_system. Skipping..."
  fi
done < "$icon_config_file"

echo "Desktop icon setup completed."

