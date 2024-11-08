#!/bin/bash
# Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'


# funct removes comments and empty lines from stdin and send it to stdout
clean_lines() {
  # or construct ensures that final line is processed also without \n
  while IFS= read -r line || [ -n "$line" ]; do
    # sed removes all comments and xarg both trims leading/trailing white-
    # space and ensures that in the output each line is terminated with /n
    clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
    # Skip empty lines and commented lines
    if [ -n "$clean_line" ]; then # -n evaluates to false if empty
      echo "$clean_line"
    fi
  done
}



