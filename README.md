# Tor Relay - Docker

[![Build and Publish](https://github.com/KolinSmith/tor-relay-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/KolinSmith/tor-relay-docker/actions/workflows/docker-publish.yml)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io-blue?logo=docker)](https://github.com/KolinSmith/tor-relay-docker/pkgs/container/tor-relay-docker)

A containerized Tor relay built from official Tor Project packages. Supports middle relays, guard nodes, and exit relays.

## Docker Image

Pull the pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/kolinsmith/tor-relay-docker:latest
```

## Understanding Tor Relay Types

The Tor network uses different types of relays, each serving a distinct role:

### 🔵 Middle Relay (Default Configuration)
Passes traffic between other Tor relays, never connecting directly to destination websites.
- ✅ **Safest option** - Your IP never appears in destination server logs
- ✅ **No exit liability** - No abuse complaints from websites
- ✅ **Easy to run** - Works on most ISPs and hosting providers
- ✅ **Still valuable** - Provides critical bandwidth to the Tor network

### 🟢 Guard Node (Automatic Promotion)
Entry point where Tor clients first connect to the network. After ~8 days of stable operation with good bandwidth and uptime, your middle relay may be **automatically promoted to Guard status** by the Tor directory authorities.
- 🎯 **No configuration needed** - Promotion is automatic based on reliability
- ⚡ **Requires stability** - High uptime and bandwidth needed
- 🔒 **Critical role** - Guards are the first hop in Tor circuits

### 🔴 Exit Relay (Advanced - Requires Special Configuration)
Final relay in the circuit that connects to destination websites and services.
- ⚠️ **Highest responsibility** - Your IP appears as the traffic source
- ⚠️ **Legal considerations** - May receive abuse complaints and DMCA notices
- ⚠️ **ISP requirements** - Many ISPs prohibit exit relays; use dedicated hosting
- ⚠️ **Reverse DNS recommended** - Set to `tor-exit.yourdomain.org`
- ⚠️ **Exit notice page** - Host explanation page at your IP
- ✅ **Most needed** - Exit relays are the most valuable to the network

See the [Exit Relay Configuration](#exit-relay-configuration) section below for setup instructions.

**📚 Learn More:**
- [Tor Relay Guide](https://community.torproject.org/relay/)
- [Lifecycle of a New Relay](https://blog.torproject.org/lifecycle-of-a-new-relay/)
- [Tips for Running an Exit Node](https://blog.torproject.org/tips-running-exit-node/)

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

- **Nickname**: `YourRelayNickname` (customize in `torrc` or `.env`)
- **Type**: Middle relay / Guard node (no exit traffic by default)
- **ORPort**: 8443 (customize in `torrc`, `.env`, or `docker-compose.yml` ports section)
- **DirPort**: 8444 (customize in `torrc`, `.env`, or `docker-compose.yml` ports section)
- **Bandwidth**: 1MB/s sustained, 1.5MB/s burst (customize in `torrc` or `.env`)
- **Memory**: ~600MB typical, 1GB limit (customize `deploy.resources.limits.memory` in `docker-compose.yml`)
- **Contact**: `your-email@example.com` (customize in `torrc` or `.env`)

> **Note**: You must update the nickname and contact info before deploying.
> - **Relay identity** (nickname, contact): Edit `torrc` or set in `.env`
> - **Ports** (ORPort, DirPort): Edit `torrc`, set in `.env`, or change port mapping in `docker-compose.yml`
> - **Bandwidth limits**: Edit `torrc` or set in `.env`
> - **Memory limits**: Edit `deploy.resources` section in `docker-compose.yml`

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

> **Why clone the repository?**
> Even when using the pre-built image, you need the configuration files (`torrc`, `docker-compose.yml`, `.env.example`) from this repository. The Docker image only contains the Tor software - your relay's configuration is stored in these files.

---

#### **Option 1: Use Pre-Built Image** (Recommended - Faster & Easier)

This pulls the ready-to-use image from GitHub Container Registry. No compilation needed.

1. **Clone the repository** (to get config files):
   ```bash
   git clone https://github.com/KolinSmith/tor-relay-docker.git
   cd tor-relay-docker
   ```

2. **Customize your relay** (required):
   ```bash
   cp .env.example .env
   # Edit .env and set your nickname, contact email, etc.
   # Or edit torrc directly
   ```

3. **Start the relay**:
   ```bash
   docker-compose up -d
   ```

   This uses `docker-compose.yml` which pulls: `ghcr.io/kolinsmith/tor-relay-docker:latest`

---

#### **Option 2: Build Locally** (For customization or development)

This builds the Docker image from source on your machine using the `Dockerfile`.

1. **Clone the repository**:
   ```bash
   git clone https://github.com/KolinSmith/tor-relay-docker.git
   cd tor-relay-docker
   ```

2. **Customize your relay** (required):
   ```bash
   cp .env.example .env
   # Edit .env and set your nickname, contact email, etc.
   ```

3. **Build and start**:
   ```bash
   docker-compose -f docker-compose.build.yml up -d --build
   ```

   This uses `docker-compose.build.yml` which builds from the `Dockerfile`.

---

#### **Common Commands** (Both Options)

**View logs**:
```bash
docker-compose logs -f tor-relay
```

**Check status**:
```bash
docker-compose ps
```

**Stop relay**:
```bash
docker-compose down
```

**Restart relay**:
```bash
docker-compose restart tor-relay
```

## Exit Relay Configuration

⚠️ **WARNING**: Running an exit relay requires careful consideration. Read the [Tips for Running an Exit Node](https://blog.torproject.org/tips-running-exit-node/) before proceeding.

### Prerequisites for Exit Relays

Before configuring an exit relay, ensure:
- ✅ **Dedicated hosting** - Use a VPS/colocation, NOT a residential connection
- ✅ **ISP approval** - Confirm your provider allows exit relays
- ✅ **Separate IP** - Use a dedicated IP address distinct from personal services
- ✅ **Reverse DNS** - Set to `tor-exit.yourdomain.org` or similar
- ✅ **Abuse handling plan** - Be prepared to respond to complaints
- ✅ **Legal review** - Consider consulting a lawyer in your jurisdiction

### Option 1: Reduced Exit Policy (Recommended)

The **Reduced Exit Policy** allows ~60 commonly-used ports while blocking abuse-prone services (like BitTorrent). This significantly reduces DMCA complaints while still providing valuable exit capacity.

Edit `torrc` and replace the exit policy line:

```bash
# Replace this line:
ExitPolicy reject *:*

# With the Reduced Exit Policy:
ExitPolicy accept *:20-21     # FTP
ExitPolicy accept *:22         # SSH
ExitPolicy accept *:23         # Telnet
ExitPolicy accept *:43         # WHOIS
ExitPolicy accept *:53         # DNS
ExitPolicy accept *:79-81      # Finger, HTTP
ExitPolicy accept *:88         # Kerberos
ExitPolicy accept *:110        # POP3
ExitPolicy accept *:143        # IMAP
ExitPolicy accept *:194        # IRC
ExitPolicy accept *:220        # IMAP3
ExitPolicy accept *:389        # LDAP
ExitPolicy accept *:443        # HTTPS
ExitPolicy accept *:464        # Kerberos
ExitPolicy accept *:465        # SMTPS
ExitPolicy accept *:531        # IRC/AIM
ExitPolicy accept *:543-544    # Kerberos
ExitPolicy accept *:554        # RTSP
ExitPolicy accept *:563        # NNTP over SSL
ExitPolicy accept *:587        # SMTP
ExitPolicy accept *:636        # LDAP over SSL
ExitPolicy accept *:706        # SILC
ExitPolicy accept *:749        # Kerberos
ExitPolicy accept *:873        # rsync
ExitPolicy accept *:902-904    # VMware
ExitPolicy accept *:981        # Remote HTTPS
ExitPolicy accept *:989-995    # FTP over SSL, Telnet over SSL, IMAP/POP over SSL
ExitPolicy accept *:1194       # OpenVPN
ExitPolicy accept *:1220       # QT Server Admin
ExitPolicy accept *:1293       # IPSec
ExitPolicy accept *:1500       # VLSI License Manager
ExitPolicy accept *:1533       # Sametime
ExitPolicy accept *:1677       # GroupWise
ExitPolicy accept *:1723       # PPTP
ExitPolicy accept *:1755       # RTSP
ExitPolicy accept *:1863       # MSNP
ExitPolicy accept *:2082       # Infowave
ExitPolicy accept *:2083       # Secure Radius
ExitPolicy accept *:2086-2087  # GNUnet, ELI
ExitPolicy accept *:2095-2096  # NBX
ExitPolicy accept *:2102-2104  # Zephyr
ExitPolicy accept *:3128       # SQUID
ExitPolicy accept *:3389       # RDP
ExitPolicy accept *:3690       # SVN
ExitPolicy accept *:4321       # RWHOIS
ExitPolicy accept *:4643       # Virtuozzo
ExitPolicy accept *:5050       # Yahoo! Messenger
ExitPolicy accept *:5190       # AIM/ICQ
ExitPolicy accept *:5222-5223  # XMPP, XMPP over SSL
ExitPolicy accept *:5228       # Android Market
ExitPolicy accept *:5900       # VNC
ExitPolicy accept *:6660-6669  # IRC
ExitPolicy accept *:6679       # IRC over SSL
ExitPolicy accept *:6697       # IRC over SSL
ExitPolicy accept *:8000       # iRDMI
ExitPolicy accept *:8008       # HTTP alternate
ExitPolicy accept *:8074       # Gadu-Gadu
ExitPolicy accept *:8080       # HTTP Proxies
ExitPolicy accept *:8082       # HTTPS Electrum Bitcoin port
ExitPolicy accept *:8087-8088  # Simplify Media SPP Protocol, Radan HTTP
ExitPolicy accept *:8232-8233  # Zcash
ExitPolicy accept *:8332-8333  # Bitcoin
ExitPolicy accept *:8443       # PCsync HTTPS
ExitPolicy accept *:8888       # HTTP Proxies, NewsEDGE
ExitPolicy accept *:9418       # git
ExitPolicy accept *:9999       # distinct
ExitPolicy accept *:10000      # Network Data Management Protocol
ExitPolicy accept *:11371      # OpenPGP hkp (keyserver)
ExitPolicy accept *:19294      # Google Voice TCP
ExitPolicy accept *:19638      # Ensim control panel
ExitPolicy accept *:50002      # Electrum Bitcoin SSL
ExitPolicy accept *:64738      # Mumble
ExitPolicy reject *:*          # Reject all other ports
```

**Reference**: [Reduced Exit Policy Documentation](https://gitlab.torproject.org/legacy/trac/-/wikis/doc/ReducedExitPolicy)

### Option 2: Full Exit Policy (Maximum Impact, Maximum Responsibility)

For maximum network impact, you can allow all exit traffic:

```bash
# Replace:
ExitPolicy reject *:*

# With:
ExitPolicy accept *:*
```

⚠️ **WARNING**: This will generate significant abuse complaints and requires robust abuse handling processes.

### Additional Exit Relay Recommendations

1. **Set up an exit notice page** - Configure `DirPortFrontPage` in `torrc` to point to an HTML file explaining your exit relay
2. **Register with ARIN/RIPE** - Get SWIP/RIPE registration so abuse goes to you, not your ISP
3. **Monitor abuse emails** - Set up a dedicated email for handling complaints
4. **Consider bandwidth limits** - Use `BandwidthRate` to leave headroom for other services
5. **Join the tor-relays mailing list** - Stay informed about best practices

**📚 Exit Relay Resources:**
- [Post-Install Configuration](https://community.torproject.org/relay/setup/post-install/)
- [Tips for Running an Exit Node](https://blog.torproject.org/tips-running-exit-node/)
- [Reduced Exit Policy](https://gitlab.torproject.org/legacy/trac/-/wikis/doc/ReducedExitPolicy)

## Migrating from Existing Relay

If you're migrating from an existing Tor relay, **preserve your relay keys** to maintain your relay's reputation and fingerprint.

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

### Interactive Monitoring with Nyx

[Nyx](https://nyx.torproject.org/) is a terminal-based monitoring tool for Tor relays that provides real-time statistics, bandwidth graphs, and connection information.

**Install Nyx** (on the Docker host):
```bash
# Debian/Ubuntu
sudo apt install nyx

# Or via pip
pip install nyx
```

**Run Nyx to monitor your relay**:
```bash
# Connect to the relay's control port
docker exec -it tor-middle-relay sudo -u debian-tor nyx
```

**Create a convenient alias** (add to `~/.bashrc` or `~/.bash_aliases`):
```bash
alias status='docker exec -it tor-middle-relay sudo -u debian-tor nyx'
```

Then simply run `status` to monitor your relay!

**Nyx provides:**
- 📊 Real-time bandwidth graphs
- 🌍 Connection information and circuit details
- 📈 Uptime and performance statistics
- ⚙️ Configuration viewer
- 📝 Log monitoring

### View Logs

```bash
# Follow logs
docker-compose logs -f tor-relay

# Last 100 lines
docker-compose logs --tail=100 tor-relay
```

### Check Relay Status on Tor Network

**Find Your Relay:**
Visit [Tor Metrics Relay Search](https://metrics.torproject.org/rs.html#search) to check if your relay is visible on the network.

You can search by:
- 🏷️ **Relay nickname** - Search for the nickname you configured
- 📧 **Contact email** - Search for your contact email address
- 🔑 **Fingerprint** - Search for your relay's unique fingerprint

**Note**: New relays typically appear within **24-48 hours** after first startup. It may take up to **8 days** to be promoted to Guard status if your relay maintains good uptime and bandwidth.

**Relay Search URL**: https://metrics.torproject.org/rs.html#search

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
