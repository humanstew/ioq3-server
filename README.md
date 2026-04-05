# ioq3-server: Multi-instance ioquake3 dedicated server stack

![Quake 3 Arena](https://upload.wikimedia.org/wikipedia/de/7/78/Quake_III_Arena_Logo.svg)

## Quick Start

1. **Clone and add game data:**
   ```sh
   git clone https://github.com/humanstew/ioq3-server.git
   cd ioq3-server
   ```
   Place `pak0.pk3` (and other `.pk3` files) in `gamedata/baseq3/`. For Team Arena, add `.pk3` files to `gamedata/missionpack/`.

   > `pak0.pk3` is not included due to copyright. You must provide your own from a Quake 3 installation.

2. **Run setup:**
   ```sh
   ./setup.sh
   ```
   This checks prerequisites, creates your `.env` file, and validates game data.

3. **Build and launch:**
   ```sh
   make build up
   ```
   Or directly: `docker compose up --build -d`

## Common Commands

Run `make` to see all available commands:

```
setup           Run initial setup (prerequisites, .env, game data check)
build           Build Docker images
up              Start all services in background
down            Stop all services
restart         Restart all services
logs            Tail logs from all services
status          Show service status and health
clean           Remove containers, volumes, and built images
```

## Project Structure

```
server/                  # Game server build & config
├── Dockerfile
├── entrypoint.sh
└── configs/
    ├── shared/          # Common to all servers
    ├── quake1-ffa/      # FFA server configs
    ├── quake2-osp/      # OSP CTF server configs
    └── quake3-ta/       # Team Arena server configs

mods/                    # Game mods
└── osp/                 # OSP mod (needs zz-osp-*.pk3)

web/                     # Web-facing services
├── Caddyfile            # Reverse proxy config
├── landing/             # Status page (Node/Express)
└── fastdl/              # Fast download (Nginx)

gamedata/                # Runtime game data (user-supplied)
├── baseq3/              # Base Q3 pak files
└── missionpack/         # Team Arena pak files
```

## Services

| Service   | Description                        | Port(s)         |
|-----------|------------------------------------|-----------------|
| `quake1`  | FFA server                         | UDP 27960       |
| `quake2`  | OSP CTF server                     | UDP 27961       |
| `quake3`  | Team Arena (missionpack) server    | UDP 27962       |
| `fastdl`  | Nginx serving custom `.pk3` files  | internal        |
| `landing` | Server status page (Node/Express)  | internal        |
| `caddy`   | Reverse proxy with auto-HTTPS      | 80, 443         |

All services include health checks. Use `make status` to see their state.

## Configuration

### Environment Variables

Set these in your `.env` file (created by `./setup.sh` from `.env.example`):

| Variable           | Description                                      | Default                         |
|--------------------|--------------------------------------------------|---------------------------------|
| `DOMAIN`           | FQDN for Let's Encrypt SSL                       | `localhost`                     |
| `FASTDL_SUBDOMAIN` | Optional subdomain for FastDL                    | disabled                        |
| `FASTDL_URL`       | Public URL clients use to download maps           | `http://localhost/fastdl`       |
| `ADMIN_PASSWORD`   | RCON password (auto-generated if unset)           | random                          |
| `SERVER_MOTD`      | Message of the day                                | `Welcome to my Quake 3 server!` |
| `FFA_CONFIG`       | FFA server config file                            | `server-ffa.cfg`                |
| `Q3TA_CONFIG`      | Team Arena server config file                     | `server-mp.cfg`                 |
| `MAPS_FFA`         | FFA map rotation config                           | `maps-ffa.cfg`                  |
| `MAPS_Q3TA`        | Team Arena map rotation config                    | `maps-q3ta.cfg`                 |
| `SITE_TITLE`       | Landing page title                                | `IOQ3 SERVER`                   |
| `SITE_SUBTITLE`    | Landing page subtitle                             | empty                           |
| `SITE_GITHUB_USER` | GitHub username for footer link                   | empty                           |

### Server Configs

At startup, the entrypoint copies `shared/` configs into `baseq3/` first, then the server-specific configs on top. To customize, edit the files in the relevant `server/configs/` subdirectory.

## Fast Download Server

The `fastdl` service is an Nginx container serving custom `.pk3` files over HTTP, proxied through Caddy with HTTPS.

- **Path-based** (default): `https://yourdomain.com/fastdl`
- **Subdomain**: Set `FASTDL_SUBDOMAIN=cdn.yourdomain.com` for `https://cdn.yourdomain.com`
- Place custom maps in `web/fastdl/public/baseq3/` or `web/fastdl/public/missionpack/`.
- Do not place official `pak0.pk3` in `web/fastdl/public/`.

## Status Page

The `landing` service queries each server via UDP and shows server status, current map, and player counts. Accessible at your domain root (e.g., `https://quake.example.com`).

Customize the title, subtitle, and branding via the `SITE_*` environment variables. Configure displayed servers via `SERVERS_JSON` in `docker-compose.yml`.

## SSL/TLS

Caddy automatically obtains and renews Let's Encrypt certificates.

**Requirements:**
- Set `DOMAIN` to your FQDN
- Ports 80 and 443 must be accessible from the internet
- DNS must point to your server's public IP

For local development, `DOMAIN=localhost` uses a self-signed certificate.

## Advanced Usage

- **Change ioquake3 version:**
  ```sh
  docker build --build-arg IOQUAKE3_COMMIT=release-1.36 -t ioq3-server ./server
  ```
- **Add more servers:** Duplicate a service block in `docker-compose.yml` with a new port mapping.

## FAQ

**Q: Why do I need to provide `pak0.pk3`?**
Game data files are copyrighted and cannot be distributed. You must supply your own.

**Q: How do I connect?**
Use your server's IP and the mapped port, e.g. `/connect your-ip:27960`.

**Q: How do I set the RCON password?**
Set `ADMIN_PASSWORD` in your `.env` file, or leave it empty for an auto-generated password.

## License

This project automates ioquake3 server deployment. Quake 3 data files are not included.
See the [ioquake3 license](https://github.com/ioquake/ioq3/blob/master/COPYING.txt) for engine details.
