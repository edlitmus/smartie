# Smartie

A Bash script that monitors the five critical SMART attributes identified by Backblaze as early warning signs of drive failure.

## Background

Based on Backblaze's data center research, the following SMART attributes are strong indicators of potential drive failure when their raw values are non-zero:

- SMART 5: Reallocated Sectors Count
- SMART 187: Reported Uncorrectable Errors
- SMART 188: Command Timeout
- SMART 197: Current Pending Sector Count
- SMART 198: Uncorrectable Sector Count

## Requirements

- Linux system with SATA drives
- `smartmontools` package installed
- Root privileges (required for accessing SMART data)

## Installation

1. Install smartmontools if not already installed:
```bash
# Ubuntu/Debian
sudo apt install smartmontools

# Fedora/RHEL
sudo dnf install smartmontools

# Arch Linux
sudo pacman -S smartmontools
```

2. Clone or download this repository to your preferred location

## Usage

Run the script as root:

```bash
sudo ./smartie.sh
```

The script will:
1. Check all SATA drives in the system
2. Monitor the five critical SMART attributes
3. Report any non-zero values, including drive model and serial number
4. Show a checkmark for drives with no issues

## Output Example

```
Smartie - SMART Drive Health Checker
WARNING: Issues found on /dev/sda
  Model: WDC WD10EZEX-00BN5A0
  Serial: WD-WCC3F7DLCK91
  ⚠️  SMART 5 (Reallocated Sectors Count): 12

⚠️  Found issues on 1 out of 2 drives
```

If no issues are found, you'll see:
```
Smartie - SMART Drive Health Checker
✓ No issues found on any of the 2 drives checked
```

## Exit Codes

- 0: Script completed successfully
- 1: Script not run as root or smartctl not installed
