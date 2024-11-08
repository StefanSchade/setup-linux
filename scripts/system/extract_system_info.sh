#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Verify output dir provided and existing
if [ $# -eq 0 ]; then
   echo "Usage: $0 <outut_directory>"
   exit 1
fi

output_dir="$1"
output_dir="${output_dir%/}"
output_file="${output_dir}/system_info.txt"

mkdir  -p "$output_dir"

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it and retry."
        exit 1
    fi
}

# Check required commands
check_command lscpu
check_command free
check_command lsblk
check_command ip
check_command upower
check_command dmidecode
check_command lspci
check_command grep

# Collect system information
{
    echo "===== System Information ====="
    echo "Hostname: $(hostname)"
    echo "Operating System: $(lsb_release -ds 2>/dev/null || uname -s)"
    echo "Kernel Version: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo ""

    echo "===== CPU Information ====="
    lscpu
    echo ""

    echo "===== Memory Information ====="
    free -h
    echo ""

    echo "===== Disk Information ====="
    lsblk
    echo ""

    echo "===== Network Information ====="
    ip addr show
    echo ""

    echo "===== Manufacturer and Model ====="
    sudo dmidecode -s system-manufacturer
    sudo dmidecode -s system-product-name
    echo ""

    echo "===== Graphics Information ====="
    lspci | grep -i vga
    echo ""

    echo "===== Battery Information ====="
    upower -i $(upower -e | grep BAT) || echo "No battery found."
    echo ""

    echo "===== DMI Information ====="
    sudo dmidecode -t system
    echo ""

    echo "===== List of Installed Packages ====="
    if command -v apt &> /dev/null; then
        dpkg -l
    elif command -v pacman &> /dev/null; then
        pacman -Q
    elif command -v dnf &> /dev/null; then
        dnf list installed
    else
        echo "Unsupported package manager."
    fi
    echo ""
} > "$output_file"

echo "System information has been saved to $output_file."

