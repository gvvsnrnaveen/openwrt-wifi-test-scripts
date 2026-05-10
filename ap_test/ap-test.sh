#!/bin/sh

#############################################################################
# Wireless Configuration Test Script
# Tests combinations of hwmode, htmode, and channel settings
# Generates CSV report of working/non-working scenarios
#############################################################################

# Configuration
INTERFACE="ath0"
CONFIG_PATH="wireless.wifi0"
BAND="2"
WAIT_TIME=5

# Define parameters (space-separated strings for sh compatibility)
hwmodes="11axa 11ac 11na 11a"
htmodes="HT20 HT40"
channels="184 188 20 21 22 23 24 25 26 27 28"

# Output CSV file
csv_file="wireless_test_results.csv"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#############################################################################
# Function: Check if running as root
#############################################################################
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root" >&2
        exit 1
    fi
}

#############################################################################
# Function: Map channel to country code
#############################################################################
get_country_for_channel() {
    local channel=$1

    case "$channel" in
        184|188)
            echo "JP"
            ;;
        20|21|22|23|24|25|26|27|28)
            echo "US"
            ;;
        *)
            echo ""
            ;;
    esac
}

#############################################################################
# Function: Check if interface exists
#############################################################################
check_interface() {
    if ! iwconfig "$INTERFACE" > /dev/null 2>&1; then
        echo "Error: Interface $INTERFACE not found" >&2
        echo "Available interfaces:"
        iwconfig 2>/dev/null | grep "^[a-z]" || echo "  No wireless interfaces found"
        exit 1
    fi
}

#############################################################################
# Function: Write CSV header
#############################################################################
write_csv_header() {
    echo "channel,hwmode,htmode,status,iwconfig_info" > "$csv_file"
}

#############################################################################
# Function: Set wireless parameters via UCI
#############################################################################
set_wireless_params() {
    local hwmode=$1
    local htmode=$2
    local channel=$3
    local country

    country=$(get_country_for_channel "$channel")

    uci set "${CONFIG_PATH}.hwmode=${hwmode}" 2>/dev/null
    uci set "${CONFIG_PATH}.htmode=${htmode}" 2>/dev/null
    uci set "${CONFIG_PATH}.band=${BAND}" 2>/dev/null
    uci set "${CONFIG_PATH}.channel=${channel}" 2>/dev/null
    if [ -n "$country" ]; then
        uci set "${CONFIG_PATH}.country=${country}" 2>/dev/null
    fi
    uci commit 2>/dev/null
}

#############################################################################
# Function: Apply settings and wait for interface to stabilize
#############################################################################
apply_and_wait() {
    wifi reload > /dev/null 2>&1
    sleep "$WAIT_TIME"
}

#############################################################################
# Function: Get iwconfig information
#############################################################################
get_iwconfig_info() {
    iwconfig "$INTERFACE" | head -n 3 | tr '\n' ' ' | tr -s ' ' 2>/dev/null
}

#############################################################################
# Function: Determine working status based on iwconfig output
# Status is "Working" if Access Point has a valid MAC address
# Status is "Not Working" if not associated or error
#############################################################################
check_status() {
    local iwconfig_output=$1

    # Check if Access Point has a valid MAC address (XX:XX:XX:XX:XX:XX format)
    if echo "$iwconfig_output" | grep -qE "Access Point: [0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}"; then
        echo "Working"
    else
        echo "Not Working"
    fi
}

#############################################################################
# Function: Format iwconfig output for CSV
#############################################################################
format_iwconfig_for_csv() {
    local iwconfig_output=$1

    # Convert multi-line output to single line and normalize spaces
    local formatted
    formatted=$(echo "$iwconfig_output" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

    # Escape double quotes
    formatted=$(echo "$formatted" | sed 's/"/\\"/g')

    echo "$formatted"
}

#############################################################################
# Main Script
#############################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Wireless Channel & Mode Combination Tester            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
check_root
check_interface

# Initialize CSV
write_csv_header

# Calculate total combinations
# Count items in each parameter set
hwmode_count=$(echo "$hwmodes" | wc -w)
htmode_count=$(echo "$htmodes" | wc -w)
channel_count=$(echo "$channels" | wc -w)
total=$((hwmode_count * htmode_count * channel_count))
current=0
working_count=0
not_working_count=0

echo "Configuration:"
echo "  Interface: $INTERFACE"
echo "  Band: $BAND"
echo "  HW Modes: $hwmodes"
echo "  HT Modes: $htmodes"
echo "  Channels: $channels"
echo "  Wait time between tests: ${WAIT_TIME}s"
echo ""
echo "Total combinations to test: $total"
echo ""
echo "Starting tests..."
echo "────────────────────────────────────────────────────────────────"
echo ""

# Iterate through all combinations
for hwmode in $hwmodes; do
    for htmode in $htmodes; do
        for channel in $channels; do
            current=$((current+1))
            # Display progress
            printf "[%3d/%3d] hwmode=%-6s htmode=%-5s channel=%-2s ... " "$current" "$total" "$hwmode" "$htmode" "$channel"

            # Set wireless parameters
            set_wireless_params "$hwmode" "$htmode" "$channel"

            # Apply settings and wait
            apply_and_wait

            # Capture iwconfig output
            iwconfig_output=$(get_iwconfig_info)

            # Determine status
            status=$(check_status "$iwconfig_output")

            # Format iwconfig info for CSV
            iwconfig_info=$(format_iwconfig_for_csv "$iwconfig_output")

            # Write to CSV
            echo "$channel,$hwmode,$htmode,$status,\"$iwconfig_info\"" >> "$csv_file"

            # Update counters and display result
            if [ "$status" = "Working" ]; then
                printf "${GREEN}✓ Working${NC}\n"
                working_count=$((working_count+1))
            else
                printf "${RED}✗ Not Working${NC}\n"
                not_working_count=$((not_working_count+1))
            fi
        done
    done
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Test Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Results Summary:"
echo "  Total combinations tested: $total"
printf "  ${GREEN}Working:${NC}     $working_count\n"
printf "  ${RED}Not Working:${NC} $not_working_count\n"
echo ""
echo "CSV Report: $csv_file"
echo ""
echo "To view results:"
echo "  cat $csv_file"
echo "  column -t -s',' $csv_file  (formatted view)"
echo ""
