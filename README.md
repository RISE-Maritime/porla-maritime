# porla-maritime

A consolidated maritime extension for [`porla`](https://github.com/RISE-Maritime/porla) that combines NMEA/NMEA2000 handling, PONTOS format support, Zenoh messaging, and Keelson data format compatibility into a single image.

This extension consolidates functionality from:
- [porla-nmea](https://github.com/RISE-Maritime/porla-nmea) - NMEA0183/NMEA2000 handling via canboat
- [porla-pontos](https://github.com/MO-RISE/porla-pontos) - PONTOS-hub data format compatibility
- [porla-zenoh](https://github.com/MO-RISE/porla-zenoh) - Zenoh messaging and Keelson codec support

## What

This extension provides tools for maritime data acquisition and transformation, enabling complete vessel data pipelines with just `porla` (base) + `porla-maritime`.

### Built-in Functionality

| Tool | Source | Description |
|------|--------|-------------|
| `ais` | porla-nmea | Encode/decode AIS messages between NMEA0183 and JSON formats |
| `lwe450` | porla-nmea | Interface to LWE450 multicast networks (IEC 61162-450) |
| `canboat2pontos` | porla-pontos | Convert canboat analyzer JSON output to PONTOS format |
| `zenoh` | porla-zenoh | Zenoh CLI for pub/sub messaging |

### 3rd-party Tools (canboat)

Tools from [canboat](https://github.com/canboat/canboat) v4.12.0:

| Tool | Description |
|------|-------------|
| `analyzer` | NMEA2000 PGN decoder, outputs JSON |
| `actisense-serial` | Interface to Actisense NGT-1 USB gateway |
| `candump2analyzer` | Convert CAN dump format to analyzer input format |
| `n2kd` | NMEA2000 daemon for network distribution |
| `raw2json` | Convert raw NMEA2000 data to JSON |
| `n2k-csv-analyzer` | CSV output analyzer for NMEA2000 |

### Keelson Codecs

The [keelson](https://github.com/RISE-Maritime/keelson) Python SDK provides codecs that integrate with zenoh-cli for encoding/decoding Keelson envelope format:

**Encoders:**
| Codec | Description |
|-------|-------------|
| `keelson-enclose-from-text` | Enclose text payload in Keelson envelope |
| `keelson-enclose-from-base64` | Enclose base64 payload in Keelson envelope |
| `keelson-enclose-from-json` | Enclose JSON payload in Keelson envelope |

**Decoders:**
| Codec | Description |
|-------|-------------|
| `keelson-uncover-to-text` | Uncover Keelson envelope to text |
| `keelson-uncover-to-base64` | Uncover Keelson envelope to base64 |
| `keelson-uncover-to-json` | Uncover Keelson envelope to JSON |

## Usage

### Tool Reference

#### analyzer (canboat)

Decodes NMEA2000 PGN messages to JSON:

```bash
# From raw NMEA2000 input
cat nmea2000.raw | analyzer --json

# With timestamp
from_bus 1 | analyzer --json | timestamp --epoch | to_bus 2
```

#### ais

Decode AIS (NMEA0183) messages to JSON:

```bash
# Decode AIS from stdin
cat ais_messages.txt | ais decode

# In a pipeline
from_bus 1 | ais decode | to_bus 2
```

#### lwe450

Interface to LWE450 multicast networks:

```bash
# Listen to NAVD transmission group
lwe450 NAVD listen

# Listen with base64 encoding
lwe450 NAVD --base64 listen

# Send to NAVD group
cat data.txt | lwe450 NAVD send
```

Available transmission groups: `MISC`, `TGTD`, `SATD`, `NAVD`, `VDRD`, `RCOM`, `TIME`, `PROP`, `USR1`-`USR8`, `BAM1`, `BAM2`, `CAM1`, `CAM2`, `NETA`, `PGP1`-`PGP4`, `PGB1`-`PGB4`

#### canboat2pontos

Convert canboat JSON output to PONTOS format:

```bash
# Convert with vessel identifier
from_bus 2 | canboat2pontos my_vessel | to_bus 3
```

Input format: `<timestamp> <canboat json output>`
Output format: `<mqtt_topic> <json_payload>`

Supported PGNs:
- 127245: Rudder angle/order
- 127250: Heading
- 127251: Rate of Turn
- 127257: Attitude (pitch, roll)
- 127489: Engine fuel consumption
- 129025: Position (rapid update)
- 129026: COG & SOG
- 129029: GNSS Position

#### zenoh (with Keelson codecs)

Publish data to Zenoh with Keelson envelope encoding:

```bash
# Publish with keelson encoding
from_bus 1 | zenoh put --key my/key/expression \
    --encode keelson-enclose-from-text \
    --line '{message}'

# Subscribe and decode keelson envelopes
zenoh sub --key 'my/key/**' \
    --decode keelson-uncover-to-json \
    --line '{key} {message}'
```

### Examples

#### Basic NMEA2000 Pipeline

Receive NMEA2000 data via UDP, decode, and publish to MQTT:

```yaml
services:
  source:
    image: ghcr.io/rise-maritime/porla:v0.5.0
    network_mode: host
    restart: unless-stopped
    command: ["socat UDP4-RECV:1457,reuseaddr STDOUT | to_bus 1"]

  transform:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 1 | analyzer --json | timestamp --epoch | to_bus 2"]

  sink:
    image: ghcr.io/rise-maritime/porla:v0.5.0
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 2 | mqtt vessel/nmea2000"]
```

#### NMEA2000 to PONTOS Format

Complete pipeline from NMEA2000 source to PONTOS-hub compatible output:

```yaml
services:
  source:
    image: ghcr.io/rise-maritime/porla:v0.5.0
    network_mode: host
    restart: unless-stopped
    command: ["socat UDP4-RECV:1457,reuseaddr STDOUT | to_bus 1"]

  decode:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 1 | analyzer --json | timestamp --epoch | to_bus 2"]

  convert:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 2 | canboat2pontos my_vessel | to_bus 3"]

  sink:
    image: ghcr.io/rise-maritime/porla:v0.5.0
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 3 | mqtt_from_topic"]
```

#### NMEA2000 to Zenoh with Keelson Format

Publish NMEA2000 data to Zenoh using Keelson envelope format:

```yaml
services:
  source:
    image: ghcr.io/rise-maritime/porla:v0.5.0
    network_mode: host
    restart: unless-stopped
    command: ["socat UDP4-RECV:1457,reuseaddr STDOUT | to_bus 1"]

  decode:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 1 | analyzer --json | timestamp --epoch | to_bus 2"]

  sink:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 2 | zenoh put --key vessel/nmea2000 --encode keelson-enclose-from-json --line '{message}'"]
```

#### LWE450 Network Interface

Receive data from LWE450 multicast network:

```yaml
services:
  lwe450_source:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["lwe450 NAVD listen | to_bus 1"]

  process:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 1 | analyzer --json | to_bus 2"]
```

#### AIS Data Processing

Decode AIS messages and publish:

```yaml
services:
  ais_source:
    image: ghcr.io/rise-maritime/porla:v0.5.0
    network_mode: host
    restart: unless-stopped
    command: ["socat UDP4-RECV:10110,reuseaddr STDOUT | to_bus 1"]

  ais_decode:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 1 | ais decode | to_bus 2"]

  sink:
    image: ghcr.io/rise-maritime/porla:v0.5.0
    network_mode: host
    restart: unless-stopped
    command: ["from_bus 2 | mqtt vessel/ais"]
```

#### Actisense NGT-1 Gateway

Read from Actisense NGT-1 USB gateway:

```yaml
services:
  actisense:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: unless-stopped
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    command: ["actisense-serial /dev/ttyUSB0 | analyzer --json | to_bus 1"]
```

## Migration from Separate Extensions

If you're currently using separate porla-nmea, porla-pontos, or porla-zenoh images, you can migrate by simply replacing the image references:

**Before:**
```yaml
services:
  transform_1:
    image: ghcr.io/mo-rise/porla-nmea
    command: ["from_bus 1 | analyzer --json | timestamp --epoch | to_bus 2"]

  transform_2:
    image: ghcr.io/mo-rise/porla-pontos
    command: ["from_bus 2 | canboat2pontos test_vessel | to_bus 3"]

  sink:
    image: ghcr.io/mo-rise/porla-zenoh
    command: ["from_bus 3 | zenoh put --key my/key --line '{message}'"]
```

**After:**
```yaml
services:
  transform_1:
    image: ghcr.io/rise-maritime/porla-maritime
    command: ["from_bus 1 | analyzer --json | timestamp --epoch | to_bus 2"]

  transform_2:
    image: ghcr.io/rise-maritime/porla-maritime
    command: ["from_bus 2 | canboat2pontos test_vessel | to_bus 3"]

  sink:
    image: ghcr.io/rise-maritime/porla-maritime
    command: ["from_bus 3 | zenoh put --key my/key --line '{message}'"]
```

All tool interfaces are preserved for drop-in replacement compatibility.

## License

Apache-2.0
