#!/bin/bash
# Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

source ./helpers/clean.sh
source ./helpers/file_utils.sh

# Check if directory argument is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

config_dir="$1"
users_file="$config_dir/users.txt"

verify_file_existence $users_file

# Check for existing users and create missing ones
echo "Processing users from $users_file..."
clean_lines < "$users_file" | while IFS= read -r username; do
  if id -u "$username" >/dev/null 2>&1; then
    echo "User '$username' already exists. Skipping..."
  else
    echo "Creating user '$username'..."
    sudo useradd -m "$username" -s /bin/bash
    echo "User '$username' created."
  fi
done

echo "User setup completed."
