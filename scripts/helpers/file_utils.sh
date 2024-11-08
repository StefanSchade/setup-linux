#!/bin/bash
# Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

# check if the users file exists
verify_file_existence() {
  if [ ! -f "$1" ]; then
    echo "Error: '$1' not found. Please provide the users.txt file."
    exit 1
  fi
}

