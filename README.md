# porla-maritime

Maritime data extension for [`porla`](https://github.com/rise-maritime/porla), providing CLI tools for processing maritime sensor data streams.

## What

This extension adds maritime-specific data processing capabilities to porla, including AIS decoding, NMEA2000 conversion, and LWE450 multicast communication.

### Built-in functionality

| Tool | Description |
|------|-------------|
| `ais` | [AIS](https://en.wikipedia.org/wiki/Automatic_identification_system) message decoder. Reads NMEA0183 AIS sentences from stdin, outputs JSON to stdout. |
| `lwe450` | [IEC 61162-450](https://en.wikipedia.org/wiki/IEC_61162) (LWE) multicast network interface. Listens to or sends UDP multicast traffic for maritime transmission groups (NAVD, SATD, etc.). |
| `canboat2pontos` | NMEA2000 to [PONTOS](https://pontos.ri.se/) format converter. Reads canboat JSON from stdin, outputs MQTT topic/payload pairs for PONTOS ingestion. |

### 3rd-party tools

| Tool | Description |
|------|-------------|
| `analyzer` | NMEA2000 message analyzer from [canboat](https://github.com/canboat/canboat) v6.1.3 |
| `actisense-serial` | Actisense NGT-1 serial interface |
| + other canboat tools | Various NMEA2000 utilities |

### Keelson

The [keelson](https://github.com/RISE-Maritime/keelson) SDK is installed so that porla's `zenoh` CLI (`zenoh-cli`) can read and write keelson data. It adds these encoders and decoders to `zenoh put` / `zenoh subscribe` / `zenoh get`:

| Encoder / decoder | Subjects | Value |
|---|---|---|
| `keelson-enclose-from-text` / `keelson-uncover-to-text` | payload `TimestampedString` or `TimestampedBytes` (`raw`, `raw_nmea0183`, `raw_lwe450`, ...) | one line of text |
| `keelson-enclose-from-base64` / `keelson-uncover-to-base64` | payload `TimestampedBytes` (`raw_nmea2000`, `raw_rtcm_v3`, ...) | base64 |
| `keelson-enclose-from-json` / `keelson-uncover-to-json` | any keelson subject | protobuf JSON |

The subject is taken from the key, `<realm>/@v0/<entity>/pubsub/<subject>/<source>`. See the [keelson SDK README](https://github.com/RISE-Maritime/keelson/tree/main/sdks/python#keelson-codec-for-zenoh-cli) for details.

Data put on the bus this way is not a full keelson producer: `zenoh put` declares no liveliness tokens and does not apply keelson's per-subject QoS, so keelson's health monitoring will not see it.

## Usage

### Examples

Decode AIS from a UDP stream:
```yaml
version: '3.8'

services:
  ais_decoder:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: always
    command:
      - socat UDP4-RECV:10110,reuseaddr STDOUT | ais decode | to_bus 1
```

Listen to LWE450 NAVD multicast and convert NMEA2000 to PONTOS format:
```yaml
version: '3.8'

services:
  nmea2000_to_pontos:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: always
    command:
      - lwe450 NAVD listen | analyzer -json | canboat2pontos vessel-123 | to_bus 2
```

Record AIS data to file:
```yaml
version: '3.8'

services:
  ais_recorder:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: always
    volumes:
      - ./data:/data
    command:
      - from_bus 1 | record /data/ais-%Y%m%d.log
```

Put the raw packets of an LWE450 group onto the keelson bus (base64 keeps them intact), and read positions back as JSON:
```yaml
version: '3.8'

services:
  lwe450_to_keelson:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: always
    command:
      - lwe450 --base64 NAVD listen | zenoh put -k rise/@v0/my_vessel/pubsub/raw_lwe450/navd --line '{value}' --encoder keelson-enclose-from-base64

  keelson_positions:
    image: ghcr.io/rise-maritime/porla-maritime
    network_mode: host
    restart: always
    command:
      - zenoh subscribe -k 'rise/@v0/my_vessel/pubsub/location_fix/**' --decoder keelson-uncover-to-json | to_bus 3
```
