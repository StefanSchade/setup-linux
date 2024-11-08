#!/bin/bash
# Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

source ./helpers/file_utils.sh

# Function to apply the keyboard layout for each user
apply_keyboard_layout() {
  local username=$1
  local layout=$2
  local variant=${3:-} # optional

  echo "Setting keyboard layout for user: $username layout: $layout variant: $variant"

  # Switch to the user and set the keyboard layout
  sudo -u "$username" setxkbmap "$layout" "$variant"

  # Check for the user's custom keymap file (e.g., ~/.Xmodmap)
  keymap_file="$config_dir/keymap_$username.txt"
  if [ -f "$keymap_file" ]; then
    echo "Applying custom keymap for user: $username from $keymap_file"
    sudo -u "$username" xmodmap "$keymap_file"
  else
    echo "No custom keymap found for user: $username. Skipping..."
  fi
}

# Check if directory argument is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <config_directory>"
  exit 1
fi

echo "updating keymap" 

config_dir="$1"
keyboard_file="$config_dir/keyboard.txt"

verify_file_existence $keyboard_file


# Process the keyboard file
echo "Processing keyboard settings from $keyboard_file..."
while IFS=',' read -r username layout variant; do
  layout=$(echo "$layout" | xargs)  # Trim spaces
  variant=$(echo "$variant" | xargs)  # Trim spaces if variant exists

  # Call the function for each user
  apply_keyboard_layout "$username" "$layout" "$variant"
done < <(grep -v '^#' "$keyboard_file")  # Ignore comment lines

echo "Keyboard setup completed."

