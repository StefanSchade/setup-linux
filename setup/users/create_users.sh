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
users_file="$config_dir/users.txt"

# Check if the users file exists
if [ ! -f "$users_file" ]; then
  echo "Error: '$users_file' not found. Please provide the users.txt file."
  exit 1
fi

# Function to clean lines by removing comments and skipping empty lines
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

