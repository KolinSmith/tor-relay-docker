# Tor Middle Relay - Docker

A containerized Tor middle relay built from official Tor Project packages. This configuration mirrors the setup running on the "operator" server.

## What is a Tor Middle Relay?

A middle relay passes traffic between Tor clients and other relays, but never connects directly to destination websites. This means:
- ✅ You help the Tor network without exit traffic liability
- ✅ Your IP address never appears in server logs
- ✅ Lower risk compared to exit relays
- ✅ Still contributes valuable bandwidth to Tor

## Features

- **Official Tor packages** from torproject.org APT repository
- **Docker-based** for easy deployment and isolation
- **Minimal image** based on Debian Bullseye Slim
- **Persistent data** for relay identity preservation
- **Resource limits** to prevent memory issues
- **Health checks** for monitoring
- **Security hardened** with minimal capabilities

## Configuration

### Current Settings

- **Nickname**: operaTor
- **Type**: Middle relay (no exit traffic)
- **ORPort**: 8443
- **DirPort**: 8444
- **Bandwidth**: 1MB/s sustained, 1.5MB/s burst
- **Memory**: ~600MB typical, 1GB limit
- **Contact**: torrelay_operator.isothermally@8shield.net

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8443 | TCP | ORPort (Tor relay connections) |
| 8444 | TCP | DirPort (Tor directory service) |
| 9051 | TCP | ControlPort (localhost only, not exposed) |

## Quick Start

### Prerequisites

- Docker
- Docker Compose
- Open firewall ports 8443 and 8444

### Deployment

1. **Clone the repository**:
   ```bash
   git clone https://github.com/KolinSmith/tor-relay-docker.git
   cd tor-relay-docker
   ```

2. **Optional: Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env if you want to customize settings
   ```

3. **Build and start**:
   ```bash
   docker-compose up -d
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
  debian:bullseye-slim \
  sh -c "cd /data && tar xzf /backup/tor-data-backup.tar.gz"

# Fix permissions
docker run --rm \
  -v tor-relay-docker_tor_data:/data \
  debian:bullseye-slim \
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
- Search for: "operaTor"
- Or by contact: torrelay_operator.isothermally@8shield.net

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
- **Contact**: torrelay_operator.isothermally@8shield.net

## License

This Docker configuration is provided as-is for running Tor relays. Tor itself is licensed under the 3-clause BSD license.

## Contributing

Feel free to open issues or pull requests for improvements!

---

**Thank you for contributing bandwidth to the Tor network!** 🧅
