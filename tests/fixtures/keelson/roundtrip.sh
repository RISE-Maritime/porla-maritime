# shellcheck shell=bash
#
# Round-trips NMEA 0183 through zenoh-cli and the keelson codecs inside one
# container: a subscriber prints every sample as JSON while two lines (one
# CRLF, one LF) are put onto raw_nmea0183 with the text codec. Prints what
# the subscriber received.
#
# Sourced, not executed, so it runs in the entrypoint shell:
#   docker run -v .../keelson:/fixtures:ro porla-maritime "source /fixtures/roundtrip.sh"

zargs=(--mode peer --cfg scouting/multicast/enabled:false)
endpoint=tcp/127.0.0.1:7447
base=test/@v0/vessel/pubsub

zenoh "${zargs[@]}" --listen "$endpoint" subscribe -k "$base/**" \
    --decoder keelson-uncover-to-json --line '{key} {value}' >/tmp/received &
subscriber=$!

# Put a marker until it comes back: the subscription is then live.
for _ in $(seq 30); do
    zenoh "${zargs[@]}" --connect "$endpoint" put -k "$base/raw/ready" \
        -v cmVhZHk= --encoder keelson-enclose-from-base64 2>/dev/null || true
    grep -q "$base/raw/ready" /tmp/received && break
    sleep 0.5
done

# The sentences start with a literal $; nothing is meant to expand.
# shellcheck disable=SC2016
printf '%s\r\n%s\n' \
    '$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47' \
    '$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A' |
    zenoh "${zargs[@]}" --connect "$endpoint" put -k "$base/raw_nmea0183/porla/0" \
        --line '{value}' --encoder keelson-enclose-from-text

sleep 1
kill "$subscriber"
grep -v "$base/raw/ready" /tmp/received
