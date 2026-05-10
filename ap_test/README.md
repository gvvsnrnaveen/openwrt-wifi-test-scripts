# WiFi Test Scripts

A collection of shell scripts for testing and validating WiFi access point (AP) configurations on OpenWrt and Linux-based systems.

## Overview

This repository contains utilities for testing WiFi hardware settings and verifying that configuration changes are properly applied and functional.

## Scripts

### ap-test.sh

A script to validate WiFi access point configurations by setting and testing various hardware parameters.

**Features:**
- Configure hardware mode (hwmode) - 802.11a, 802.11b/g, 802.11n, 802.11ac, 802.11ax, etc.
- Set HT mode (htmode) - channel width and guard interval settings (HT20, HT40, VHT80, etc.)
- Select specific WiFi channel (1-165 depending on region)
- Set regulatory country code for compliance
- Automatically restart WiFi interface to apply settings
- Verify that changes are properly applied and working

**Usage:**
```bash
./ap-test.sh [OPTIONS]
```

**Options:**
- `--hwmode <mode>` - Set hardware mode (a, b, g, n, ac, ax)
- `--htmode <mode>` - Set HT mode (HT20, HT40, VHT80, HE80, etc.)
- `--channel <num>` - Set WiFi channel (1-165)
- `--country <code>` - Set country code (US, GB, DE, etc.)

**Example:**
```bash
./ap-test.sh --hwmode a --htmode VHT80 --channel 36 --country US
```

## Requirements

- OpenWrt system or Linux-based distribution with UCI configuration system
- `uci` command-line tool
- `wifi` or `/etc/init.d/network restart` for WiFi service management
- Root or sudo privileges
- Basic knowledge of WiFi standards and UCI configuration

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/wifi-test-scripts.git
cd wifi-test-scripts
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Verify you have the required tools installed:
```bash
which uci
which wifi
```

## Configuration Reference

### Hardware Modes (hwmode)
- `b` - 802.11b (2.4 GHz, legacy)
- `g` - 802.11g (2.4 GHz)
- `a` - 802.11a (5 GHz)
- `n` - 802.11n (2.4/5 GHz, MIMO)
- `ac` - 802.11ac (5 GHz, high throughput)
- `ax` - 802.11ax (2.4/5/6 GHz, WiFi 6)

### HT Modes (htmode)
- `HT20` - 20 MHz channel width
- `HT40` - 40 MHz channel width
- `VHT80` - 80 MHz channel width (802.11ac)
- `VHT160` - 160 MHz channel width (802.11ac)
- `HE80` - 80 MHz channel width (802.11ax)
- `HE160` - 160 MHz channel width (802.11ax)

### Channels
- **2.4 GHz Band**: 1-13 (varies by country, 14 in Japan)
- **5 GHz Band**: 36-48, 52-144, 149-165 (varies by country)
- **6 GHz Band**: 1-233 (new with WiFi 6E, country dependent)

## Troubleshooting

**Script fails with "command not found":**
- Ensure `uci` is installed: `opkg install uci` (on OpenWrt)
- Check PATH environment variable

**WiFi doesn't restart:**
- Check if running with sufficient privileges: `sudo`
- Verify the restart command: `/etc/init.d/network restart` or `wifi restart`

**Invalid configuration error:**
- Verify channel is allowed for the selected country code
- Ensure hwmode and htmode are compatible combinations
- Check country code is valid (use 2-letter or 3-letter ISO codes)

**Settings not persisting after reboot:**
- Verify changes were written to UCI: `uci show wireless`
- Ensure changes are committed: `uci commit wireless`

## Contributing

Contributions are welcome! Please:
1. Test scripts thoroughly before submitting
2. Add comments for complex operations
3. Include proper error checking
4. Document any new features

## License

[Specify your license here - MIT, GPL, etc.]

## Support

For issues, questions, or suggestions, please open an issue on GitHub or contact the maintainer.

## Disclaimer

These scripts modify system network configuration. Use with caution and ensure you have a way to recover if something goes wrong (e.g., serial console access, SSH access). Test in non-production environments first.


