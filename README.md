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
