#!/bin/sh
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

echo ""
echo "${BOLD}ioq3-server setup${NC}"
echo "=============================="
echo ""

# --- 1. Check prerequisites ---

if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed. Install it from https://docs.docker.com/get-docker/"
    exit 1
fi
info "Docker found"

if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
    info "Docker Compose found"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
    info "docker-compose found"
else
    error "Docker Compose is not installed."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    error "Docker daemon is not running. Start it and try again."
    exit 1
fi
info "Docker daemon is running"

echo ""

# --- 2. Environment file ---

if [ -f .env ]; then
    info ".env file already exists (skipping creation)"
else
    cp .env.example .env

    printf "Enter your domain [localhost]: "
    read DOMAIN
    DOMAIN="${DOMAIN:-localhost}"
    sed -i "s|^DOMAIN=.*|DOMAIN=${DOMAIN}|" .env

    printf "Enter admin/RCON password [auto-generate]: "
    read ADMIN_PASS
    if [ -n "${ADMIN_PASS}" ]; then
        sed -i "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=${ADMIN_PASS}|" .env
    fi

    if [ "${DOMAIN}" != "localhost" ]; then
        sed -i "s|^FASTDL_URL=.*|FASTDL_URL=https://${DOMAIN}/fastdl|" .env
    fi

    info ".env created from .env.example"
fi

echo ""

# --- 3. Validate game data ---

ERRORS=0

if [ -f gamedata/baseq3/pak0.pk3 ]; then
    info "gamedata/baseq3/pak0.pk3 found"
else
    error "gamedata/baseq3/pak0.pk3 not found!"
    echo "       The server requires Quake 3 game data to run."
    echo "       Copy pak0.pk3 from your Quake 3 installation into gamedata/baseq3/."
    ERRORS=1
fi

if [ -d gamedata/missionpack ] && [ -z "$(ls gamedata/missionpack/*.pk3 2>/dev/null)" ]; then
    warn "gamedata/missionpack/ has no .pk3 files — Team Arena server won't work"
fi

if [ -z "$(ls mods/osp/zz-osp-*.pk3 2>/dev/null)" ]; then
    warn "mods/osp/ has no zz-osp-*.pk3 files — OSP server won't work"
    echo "       Download the OSP 1.03 distribution and copy zz-osp-*.pk3 into mods/osp/."
fi

echo ""

# --- 4. Create directories ---

mkdir -p logs
mkdir -p gamedata/baseq3
mkdir -p gamedata/missionpack
mkdir -p web/fastdl/public/baseq3
mkdir -p web/fastdl/public/missionpack
info "Required directories created"

echo ""

# --- 5. Summary ---

if [ "${ERRORS}" -ne 0 ]; then
    error "Setup incomplete — fix the errors above and run again."
    exit 1
fi

echo "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "  Build and start:  ${COMPOSE} up --build -d"
echo "  View logs:        ${COMPOSE} logs -f"
echo "  Stop:             ${COMPOSE} down"
echo ""
