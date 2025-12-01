#!/usr/bin/env bash

# set -euo pipefail
# set -x

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if smartctl is installed
if ! command -v smartctl &> /dev/null; then
    echo "smartctl is not installed. Please install smartmontools package."
    exit 1
fi

# Critical SMART attributes to check
declare -A SMART_ATTRS
SMART_ATTRS[5]="Reallocated Sectors Count"
SMART_ATTRS[187]="Reported Uncorrectable Errors"
SMART_ATTRS[188]="Command Timeout"
SMART_ATTRS[197]="Current Pending Sector Count"
SMART_ATTRS[198]="Uncorrectable Sector Count"

HOST_OS=$(uname -s)

# Function to check SMART attributes for a drive
check_smart_attrs() {
    local drive=$1
    local found_issues=0
    
    # Get drive info
    local model=""
    local serial=""

    if [ "$HOST_OS" == "FreeBSD" ]; then
        disk=$(basename "$drive")
        model=$(camcontrol devlist | grep "$disk)" | sed -n 's/.*<\([^>]*\)>.*/\1/p')
        serial=$(smartctl -d sat,auto -i "/dev/$drive" | grep -i "Serial Number" | cut -d: -f2 | xargs)
    else
        model=$(smartctl -i "$drive" | grep "Product" | cut -d: -f2 | xargs)
        serial=$(smartctl -i "$drive" | grep "Serial Number" | cut -d: -f2 | xargs)
    fi

    # Check each critical attribute
    while read -r line; do
        # Skip header lines and empty lines
        [[ "$line" =~ ^[[:space:]]*[0-9] ]] || continue
        
        # Parse SMART attribute line
        id=$(echo "$line" | awk '{print $1}')
        raw_value=$(echo "$line" | awk '{print $10}')
        
        # Check if this is one of our monitored attributes
        if [[ -n "${SMART_ATTRS[$id]}" ]]; then
            # Convert raw value to integer, defaulting to 0 if not a number
            raw_num=$(echo "$raw_value" | grep -o '^[0-9]\+' || echo "0")
            if [ "$raw_num" -ne 0 ]; then
                if [ $found_issues -eq 0 ]; then
                    echo "WARNING: Issues found on $drive"
                    echo "  Model: $model"
                    echo "  Serial: $serial"
                    found_issues=1
                fi
                echo "  ⚠️  SMART $id (${SMART_ATTRS[$id]}): $raw_value"
            fi
        fi
    done < <(smartctl -A "$drive")
    
    return $found_issues
}

echo "Smartie - SMART Drive Health Checker"

# Find all SATA drives
total_drives=0
problem_drives=0
disk_list_cmd="lsblk -d -n -o NAME | grep -E '^sd'"

if [ "$HOST_OS" == "FreeBSD" ]; then
    disk_list_cmd="geom disk list | grep Name | awk '{print \$3}'"
fi

for drive in $(eval $disk_list_cmd); do
    ((total_drives++))
    check_smart_attrs "/dev/$drive"
    if [ $? -eq 1 ]; then
        ((problem_drives++))
        echo
    fi
done

if [ $problem_drives -eq 0 ]; then
    echo "✓ No issues found on any of the $total_drives drives checked"
else
    echo "⚠️  Found issues on $problem_drives out of $total_drives drives"
fi

exit 0
