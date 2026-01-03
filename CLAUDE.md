# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a maritime data extension for [porla](https://github.com/MO-RISE/porla), providing CLI tools for processing maritime sensor data streams. The tools operate as stdin/stdout processors designed to be composed in shell pipelines.

## Build and Test Commands

```bash
docker build -t porla-maritime .          # Build Docker image
bats tests/                               # Run all tests
bats tests/test-extension.bats            # Run single test file
black bin/ && pylint bin/                 # Lint Python code
shellcheck <script>                       # Lint shell scripts
pip install -r requirements_dev.txt       # Install dev dependencies
```

CI runs ShellCheck and BATS tests on all PRs to main.

## Architecture

All tools follow a pipeline architecture using stdin/stdout, designed for composition:

```bash
# Example: Listen to multicast, decode NMEA2000, convert to PONTOS format
lwe450 NAVD listen | analyzer -json | canboat2pontos vessel-123

# Example: Decode AIS from file
cat ais-data.nmea | ais decode
```

### CLI Tools (bin/)

**ais** - AIS message decoder (encode not yet implemented)
- Input: NMEA0183 AIS sentences
- Output: JSON (one object per line)
- Subcommands: `decode`

**lwe450** - LWE450 multicast network interface
- Transmission groups: NAVD, SATD, MISC, TGTD, VDRD, RCOM, TIME, PROP, USR1-8, BAM1-2, CAM1-2, NETA, PGP1-4, PGB1-4
- Subcommands: `listen` (multicast → stdout), `send` (stdin → multicast)
- Options: `--base64`, `--interface`, `--TTL`

**canboat2pontos** - NMEA2000 to PONTOS format converter
- Input: `<timestamp> <canboat json>` (one per line)
- Output: `<mqtt_topic> <json_payload>` (PONTOS format)
- Supported PGNs: 127245 (Rudder), 127250 (Heading), 127251 (Rate of Turn), 127257 (Attitude), 127489 (Engine/Fuel), 129025 (Position Rapid), 129026 (COG/SOG), 129029 (GNSS Position)

### Key Dependencies

- **pyais** - AIS message encoding/decoding
- **parse** - String parsing for canboat input format
- **keelson** - Maritime data utilities
- **canboat** - NMEA2000 tools (built from source in Docker)

### Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) with bats-support, bats-assert, and bats-file helpers. Test helpers are installed via `.devcontainer/post-create-script.sh`.

### Docker Build

Multi-stage build: compiles canboat v6.1.3 from source, then layers on `ghcr.io/rise-maritime/porla:v0.5.0`.
