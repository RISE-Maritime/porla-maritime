# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a maritime data extension for [porla](https://github.com/MO-RISE/porla), providing CLI tools for processing maritime sensor data streams. The tools operate as stdin/stdout processors designed to be composed in shell pipelines.

## Build and Test Commands

**Build Docker image:**
```bash
docker build -t porla-maritime .
```

**Run tests:**
```bash
bats tests/
```

**Run a single test file:**
```bash
bats tests/test-extension.bats
```

**Lint Python code:**
```bash
black bin/
pylint bin/
```

**Lint shell scripts:**
```bash
shellcheck <script>
```

**Install dependencies (development):**
```bash
pip install -r requirements_dev.txt
```

## Architecture

### CLI Tools (bin/)

All tools follow a pipeline architecture using stdin/stdout:

- **ais** - AIS message decoder. Reads NMEA0183 AIS sentences from stdin, outputs JSON to stdout. Uses `pyais` library.
- **lwe450** - LWE450 multicast network interface. Listens to or sends UDP multicast traffic for maritime data transmission groups (NAVD, SATD, etc.).
- **canboat2pontos** - NMEA2000 to PONTOS format converter. Reads canboat JSON format from stdin, outputs PONTOS-formatted MQTT topic/payload pairs. Handles PGNs for heading, position, rudder, attitude, etc.

### Key Dependencies

- **pyais** - AIS message encoding/decoding
- **parse** - String parsing for canboat input format
- **keelson** - Maritime data utilities
- **canboat** - NMEA2000 tools (built from source in Docker)

### Testing

Tests use [bats-core](https://github.com/bats-core/bats-core) with bats-support, bats-assert, and bats-file helpers. Test helpers are installed via `.devcontainer/post-create-script.sh`.

### Docker Build

The Dockerfile uses a multi-stage build:
1. Build stage compiles canboat tools from source
2. Final stage is based on `ghcr.io/rise-maritime/porla:v0.5.0`
