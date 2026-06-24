#!/bin/bash
set -euo pipefail

TORRC_SRC="/etc/tor/torrc"
TORRC_TMP="/tmp/torrc"

cp "$TORRC_SRC" "$TORRC_TMP"

if [ -n "${TOR_NICKNAME:-}" ]; then
    sed -i "s/^Nickname .*/Nickname ${TOR_NICKNAME}/" "$TORRC_TMP"
fi

if [ -n "${TOR_CONTACT:-}" ]; then
    sed -i "s/^ContactInfo .*/ContactInfo ${TOR_CONTACT}/" "$TORRC_TMP"
fi

if [ -n "${TOR_BANDWIDTH_RATE:-}" ]; then
    sed -i "s/^RelayBandwidthRate .*/RelayBandwidthRate ${TOR_BANDWIDTH_RATE} KBytes/" "$TORRC_TMP"
fi

if [ -n "${TOR_BANDWIDTH_BURST:-}" ]; then
    sed -i "s/^RelayBandwidthBurst .*/RelayBandwidthBurst ${TOR_BANDWIDTH_BURST} KBytes/" "$TORRC_TMP"
fi

# Clear stale nyx sqlite cache — avoids Cache._conn AttributeError on schema mismatch
rm -rf /var/lib/tor/.cache/nyx/ 2>/dev/null || true

exec tor -f "$TORRC_TMP"
