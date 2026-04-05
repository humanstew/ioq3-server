#!/bin/sh
echo "Launching ioquake3 server version ${IOQUAKE3_COMMIT}..."

if [ ! -f /opt/quake3/baseq3/pak0.pk3 ]; then
    echo "ERROR: pak0.pk3 not found in baseq3/."
    echo "The server cannot start without game data."
    echo "Place pak0.pk3 in the baseq3/ directory and try again."
    exit 1
fi

if [ -d /opt/quake3/baseq3/logs ] && [ ! -w /opt/quake3/baseq3/logs ]; then
    echo "WARNING: baseq3/logs/ is not writable. Server logs may not be saved."
fi

if [ "$(ls -A /opt/quake3/configs/shared 2>/dev/null)" ]; then
    echo "Copying shared configs..."
    cp /opt/quake3/configs/shared/* /opt/quake3/baseq3/
fi

if [ "$(ls -A /opt/quake3/configs/server 2>/dev/null)" ]; then
    echo "Copying server configs..."
    cp /opt/quake3/configs/server/* /opt/quake3/baseq3/
fi

if [ -z "${SERVER_ARGS}" ]; then
    echo "No additional server arguments found; running default Deathmatch configuration."
    SERVER_ARGS="+exec server_ffa.cfg"
fi

: "${SERVER_MOTD:=Welcome to my Quake 3 server!}"

if [ -z "${ADMIN_PASSWORD}" ]; then
    ADMIN_PASSWORD=$(head -c 32 /dev/urandom | base64)
    echo "No admin password set; generated a random one."
fi

FASTDL_ARGS=""
if [ -n "${FASTDL_URL}" ]; then
    echo "Fast download enabled via ${FASTDL_URL}."
    FASTDL_ARGS="+seta sv_allowDownload 1 +seta sv_dlURL \"${FASTDL_URL}\""
fi

IOQ3DED_BIN=$(ls /opt/quake3/ioq3ded*)
if [ $(echo "${IOQ3DED_BIN}" | wc -l) -gt 1 ]; then
    echo "Found more than one file matching /opt/quake3/ioq3ded*:"
    echo "${IOQ3DED_BIN}"
    exit 1
fi

exec ${IOQ3DED_BIN} \
    +set dedicated 1 \
    ${SERVER_ARGS} \
    +seta rconPassword "${ADMIN_PASSWORD}" \
    +g_motd "${SERVER_MOTD}" \
    ${FASTDL_ARGS}
