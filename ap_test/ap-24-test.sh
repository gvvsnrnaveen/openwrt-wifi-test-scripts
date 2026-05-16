#!/bin/sh

channels="182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 1 2 3 4 5 6 7 8 9 10 11 12 13 14 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243"
hwmodes="11axg 11ng 11n 11g"
CHECK_INTERFACE="ath1"
CONFIG_PATH="wireless.wifi1"
CSV_FILE="ap24_test_results.csv"
WAIT_TIME=2

check_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "Error: run this script as root" >&2
		exit 1
	fi
}

check_interface() {
	if ! iwconfig "$CHECK_INTERFACE" >/dev/null 2>&1; then
		echo "Error: interface $CHECK_INTERFACE not found" >&2
		exit 1
	fi
}

channel_to_frequency_mhz() {
	local channel="$1"

	# 2.4GHz channels follow a different mapping than channel > 14.
	if [ "$channel" -eq 14 ]; then
		echo "2484"
	elif [ "$channel" -le 13 ]; then
		echo $((2407 + (channel * 5)))
	else
		echo $((5000 + (channel * 5)))
	fi
}

get_iwconfig_info() {
	iwconfig "$CHECK_INTERFACE" 2>/dev/null | head -n 3 | tr '\n' ' ' | tr -s ' '
}

check_status() {
	local iwconfig_output="$1"

	if echo "$iwconfig_output" | grep -qE "Access Point: [0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}"; then
		echo "success"
	else
		echo "failure"
	fi
}

set_wireless_params() {
	local channel="$1"
	local hwmode="$2"

	uci set "${CONFIG_PATH}.channel=${channel}" 2>/dev/null
	uci set "${CONFIG_PATH}.hwmode=${hwmode}" 2>/dev/null
	uci commit wireless 2>/dev/null
}

apply_changes() {
	wifi reload >/dev/null 2>&1
	sleep "$WAIT_TIME"
}

write_csv_header() {
	echo "channel,frequency,hwmode,status,iwconfig_info" > "$CSV_FILE"
}

main() {
	local channel
	local hwmode
	local frequency
	local status
	local iwconfig_output
	local total
	local current=0

	check_root
	check_interface
	write_csv_header

	total=$(( $(echo "$channels" | wc -w) * $(echo "$hwmodes" | wc -w) ))

	echo "Starting test run: $total combinations"
	echo "CSV: $CSV_FILE"

	for channel in $channels; do
		frequency=$(channel_to_frequency_mhz "$channel")
		for hwmode in $hwmodes; do
				current=$((current + 1))
				printf "[%4d/%4d] channel=%s hwmode=%s ... " "$current" "$total" "$channel" "$hwmode"

				set_wireless_params "$channel" "$hwmode" 
				apply_changes

				iwconfig_output=$(get_iwconfig_info)
				status=$(check_status "$iwconfig_output")

				echo "$channel,$frequency,$hwmode,$status,\"$iwconfig_output\"" >> "$CSV_FILE"
				echo "$status"
		done
	done

	echo "Test run complete. Results saved to $CSV_FILE"
}

main "$@"

