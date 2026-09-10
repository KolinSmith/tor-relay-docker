# Tor Middle Relay Docker Image
# Based on Debian Bookworm with official Tor packages

FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    gnupg \
    wget \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Add Tor Project's official APT repository
RUN echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main" \
    > /etc/apt/sources.list.d/tor.list \
    && echo "deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main" \
    >> /etc/apt/sources.list.d/tor.list

# Import Tor Project's GPG key
RUN wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
    | gpg --dearmor > /usr/share/keyrings/tor-archive-keyring.gpg

# Cache-bust for the Tor install layer below. `tor` is intentionally unpinned so
# each fresh build pulls the current release from the Tor Project apt repo. Bump
# this value (or pass --build-arg TOR_APT_REFRESH=<anything-new>) to force the
# layer to rebuild and pick up a new Tor release. CI passes a unique value on
# every run, so scheduled/dispatch builds always re-resolve.
ARG TOR_APT_REFRESH=2026-09-10

# Install Tor and nyx monitoring tool
# nyx provides interactive monitoring via: docker exec -it -e TERM=$TERM tor-middle-relay nyx
RUN echo "tor apt refresh: ${TOR_APT_REFRESH}" \
    && apt-get update && apt-get install -y \
    tor \
    tor-geoipdb \
    nyx \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i \
       's/self\._conn\.close()/if hasattr(self, "_conn"): self._conn.close()/g' \
       /usr/lib/python3/dist-packages/nyx/__init__.py

# Create necessary directories with proper permissions
# /.nyx/ is world-writable so any runtime UID can write nyx's cache file.
# The compose user (108:113) differs from the image's debian-tor (uid 101),
# so chown alone is not sufficient — chmod 777 lets the actual runtime user write.
RUN mkdir -p /var/lib/tor /var/log/tor /etc/tor /.nyx \
    && chown -R debian-tor:debian-tor /var/lib/tor /var/log/tor \
    && chmod 700 /var/lib/tor \
    && chmod 777 /.nyx

# Entrypoint: substitutes TOR_NICKNAME, TOR_CONTACT, TOR_BANDWIDTH_* env vars
# into a copy of torrc before starting Tor (torrc mount is read-only)
COPY --chown=debian-tor:debian-tor entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports
# ORPort: 8443 - Tor relay port
# DirPort: 8444 - Directory port
# ControlPort: 9051 - Control port (localhost only)
EXPOSE 8443 8444 9051

# Switch to debian-tor user
USER debian-tor

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD pidof tor || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
