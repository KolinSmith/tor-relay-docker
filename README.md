# Tor Middle Relay - Docker

[![Build and Publish](https://github.com/KolinSmith/tor-relay-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/KolinSmith/tor-relay-docker/actions/workflows/docker-publish.yml)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io-blue?logo=docker)](https://github.com/KolinSmith/tor-relay-docker/pkgs/container/tor-relay-docker)

A containerized Tor middle relay built from official Tor Project packages. This configuration mirrors the setup running on the "operator" server.

## Docker Image

Pull the pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/kolinsmith/tor-relay-docker:latest
```

## What is a Tor Middle Relay?

A middle relay passes traffic between Tor clients and other relays, but never connects directly to destination websites. This means:
- ✅ You help the Tor network without exit traffic liability
- ✅ Your IP address never appears in server logs
- ✅ Lower risk compared to exit relays
- ✅ Still contributes valuable bandwidth to Tor

## Features

- **Official Tor packages** from torproject.org APT repository
- **Docker-based** for easy deployment and isolation
- **Minimal image** based on Debian Bookworm Slim
- **Multi-architecture** support (amd64, arm64)
- **Persistent data** for relay identity preservation
- **Resource limits** to prevent memory issues
- **Health checks** for monitoring
- **Security hardened** with minimal capabilities

## Configuration

### Default Settings

These are example defaults that **you should customize** for your relay:

- **Nickname**: `YourRelayNickname` (change in `torrc` or `.env`)
- **Type**: Middle relay (no exit traffic)
- **ORPort**: 8443 (change in `torrc`, `.env`, or `docker-compose.yml` ports section)
- **DirPort**: 8444 (change in `torrc`, `.env`, or `docker-compose.yml` ports section)
- **Bandwidth**: 1MB/s sustained, 1.5MB/s burst (change in `torrc` or `.env`)
- **Memory**: ~600MB typical, 1GB limit (change `deploy.resources.limits.memory` in `docker-compose.yml`)
- **Contact**: `your-email@example.com` (change in `torrc` or `.env`)

> **Note**: You must update the nickname and contact info before deploying.
> - **Relay identity** (nickname, contact): Edit `torrc` or set in `.env`
> - **Ports** (ORPort, DirPort): Edit `torrc`, set in `.env`, or change port mapping in `docker-compose.yml`
> - **Bandwidth limits**: Edit `torrc` or set in `.env`
> - **Memory limits**: Edit `deploy.resources` section in `docker-compose.yml`

### Ports

These are the **default example ports**. You can use any available ports, but you must configure them consistently across all config files.

| Port | Protocol | Purpose | Customizable |
|------|----------|---------|--------------|
| 8443 | TCP | ORPort (Tor relay connections) | Yes - change in `torrc`, `.env`, and `docker-compose.yml` ports section |
| 8444 | TCP | DirPort (Tor directory service) | Yes - change in `torrc`, `.env`, and `docker-compose.yml` ports section |
| 9051 | TCP | ControlPort (localhost only, not exposed) | Yes - change in `torrc` only (not exposed externally) |

> **Note**: If you change ports, you must update them in **all three locations**:
> 1. **`torrc`**: Set `ORPort` and `DirPort` values
> 2. **`.env`**: Set `TOR_OR_PORT` and `TOR_DIR_PORT` (optional if using torrc)
> 3. **`docker-compose.yml`**: Update the `ports:` section to match (e.g., `"9443:9443"` instead of `"8443:8443"`)
>
> The port numbers are **not special** - they're just examples. Choose any available ports that work for your network.

## Quick Start

### Prerequisites

- Docker
- Docker Compose
- Open firewall ports 8443 and 8444

### Deployment

**Option 1: Use pre-built image (recommended)**

1. **Clone the repository**:
   ```bash
   git clone https://github.com/KolinSmith/tor-relay-docker.git
   cd tor-relay-docker
   ```

2. **Update docker-compose.yml to use GHCR image**:
   ```yaml
   services:
     tor-relay:
       image: ghcr.io/kolinsmith/tor-relay-docker:latest
       # ... rest of config
   ```

3. **Start**:
   ```bash
   docker-compose up -d
   ```

**Option 2: Build locally**

1. **Clone and configure**:
   ```bash
   git clone https://github.com/KolinSmith/tor-relay-docker.git
   cd tor-relay-docker
   cp .env.example .env  # Optional customization
   ```

2. **Build and start**:
   ```bash
   docker-compose up -d --build
   ```

4. **View logs**:
   ```bash
   docker-compose logs -f tor-relay
   ```

5. **Check status**:
   ```bash
   docker-compose ps
   ```

## Migrating from Existing Relay

If you're migrating from an existing Tor relay (like operator server), **preserve your relay keys** to maintain your relay's reputation and fingerprint.

### 1. Backup Tor Data

On your current relay server:
```bash
sudo tar -czf /tmp/tor-backup.tar.gz -C /var/lib/tor .
```

### 2. Copy to New Server

```bash
scp user@old-server:/tmp/tor-backup.tar.gz ./tor-data-backup.tar.gz
```

### 3. Extract to Docker Volume

```bash
# Start containers once to create volumes
docker-compose up -d
docker-compose down

# Extract backup into tor_data volume
docker run --rm \
  -v tor-relay-docker_tor_data:/data \
  -v $(pwd):/backup \
  debian:bookworm-slim \
  sh -c "cd /data && tar xzf /backup/tor-data-backup.tar.gz"

# Fix permissions
docker run --rm \
  -v tor-relay-docker_tor_data:/data \
  debian:bookworm-slim \
  sh -c "chown -R 108:113 /data"  # debian-tor UID:GID
```

### 4. Start the Relay

```bash
docker-compose up -d
```

Your relay will resume with the same fingerprint and reputation!

## Monitoring

### View Logs

```bash
# Follow logs
docker-compose logs -f tor-relay

# Last 100 lines
docker-compose logs --tail=100 tor-relay
```

### Check Relay Status

- **Tor Metrics**: https://metrics.torproject.org/rs.html
- Search for your relay nickname
- Or search by your contact email

### Resource Usage

```bash
# Container stats
docker stats tor-middle-relay

# Memory usage
docker exec tor-middle-relay sh -c "cat /proc/\$(pidof tor)/status | grep -E '(VmRSS|VmSize)'"
```

## Maintenance

### Update Tor

```bash
# Rebuild with latest packages
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Restart Relay

```bash
docker-compose restart tor-relay
```

### Stop Relay

```bash
docker-compose down
```

### Clean Up Completely

```bash
# WARNING: This deletes your relay keys!
docker-compose down -v
```

## Configuration Files

- **`Dockerfile`**: Custom image based on Debian with official Tor packages
- **`docker-compose.yml`**: Service definition with ports, volumes, and limits
- **`torrc`**: Tor configuration (middle relay, no exits)
- **`.env.example`**: Environment variable template

## Security

- **No exit traffic**: `ExitPolicy reject *:*`
- **No new privileges**: Container runs with `no-new-privileges:true`
- **Capability dropped**: All Linux capabilities dropped
- **Read-only filesystem**: Where possible (Tor data needs writes)
- **Resource limits**: Memory capped at 1GB
- **Runs as `debian-tor`**: Non-root user

## Troubleshooting

### Relay not showing up on Tor Metrics

- Wait 24-48 hours after first start
- Check logs for errors: `docker-compose logs tor-relay`
- Verify ports 8443 and 8444 are open in firewall
- Ensure sufficient bandwidth (minimum 75 KB/s)

### High memory usage

Current config allows up to 1GB. If you need to reduce:

1. Edit `docker-compose.yml` and lower `memory` limits
2. Add `MaxMemInQueues` to `torrc`: `MaxMemInQueues 512 MB`
3. Restart: `docker-compose restart`

### Container keeps restarting

```bash
# Check logs
docker-compose logs tor-relay

# Common issues:
# - Incorrect file permissions in /var/lib/tor
# - Invalid torrc configuration
# - Port conflicts (8443/8444 already in use)
```

## Architecture Support

This image builds on:
- **amd64** (x86_64) - Intel/AMD processors
- **arm64** (aarch64) - ARM 64-bit (Raspberry Pi 4, Orange Pi, etc.)

The Tor Project's official packages support both architectures.

## Resources

- **Tor Project**: https://www.torproject.org/
- **Tor Relay Guide**: https://community.torproject.org/relay/
- **Tor Metrics**: https://metrics.torproject.org/

## License

This Docker configuration is provided as-is for running Tor relays. Tor itself is licensed under the 3-clause BSD license.

## Contributing

Feel free to open issues or pull requests for improvements!

---

**Thank you for contributing bandwidth to the Tor network!** 🧅
