import express from 'express';
import {GameDig} from 'gamedig';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const app = express();
const port = process.env.PORT || 3000;

// Serve static assets (place your tile image at landing/public/tile.png)
app.use(express.static('public'));

const defaultServers = [
  { name: 'FFA', host: 'quake1', port: 27960 },
  { name: 'CTF', host: 'quake2', port: 27960 },
  { name: 'Q3TA', host: 'quake3', port: 27960 },
];

let servers;
try {
  servers = JSON.parse(process.env.SERVERS_JSON || 'null') || defaultServers;
} catch (error) {
  console.warn('Invalid SERVERS_JSON provided. Falling back to defaults.', error.message);
  servers = defaultServers;
}

async function fetchStatus(server) {
  try {
    const state = await GameDig.query({
      type: 'q3a',
      host: server.host,
      port: server.port,
      socketTimeout: 1000,
      givenPortOnly: true,
      debug: false,
      maxAttempts: 1,
    });

    return {
      ...server,
      online: true,
      hostname: state.name || server.name,
      map: state.map,
      players: state.players.length,
      maxPlayers: state.maxplayers,
      motd: state.raw?.rules?.g_motd || '',
    };
  } catch (error) {
    return {
      ...server,
      online: false,
      error: error.message,
    };
  }
}

function renderHtml(statuses) {
  const year = new Date().getFullYear();
  const rows = statuses
    .map((status, index) => {
      const zebra = index % 2 === 0 ? '#1a1a1a' : '#111';
      const badgeColor = status.online ? '#5dfc5d' : '#ff5e5e';
      const badgeText = status.online ? 'ONLINE' : 'OFFLINE';
      const detail = status.online
        ? `${status.players}/${status.maxPlayers} players — Map: ${status.map}`
        : status.error || 'No response';

      return `
        <tr style="background:${zebra};">
          <td style="padding:12px 16px; border:1px solid #333;">
            <div style="font-weight:bold; letter-spacing:2px; color:#ffdd57;">${status.name}</div>
            <div style="font-size:12px; color:#aaa;">${status.host.replace(/^quake[0-9]/, 'quake.pklan.net')}:${status.displayPort || status.port}</div>
          </td>
          <td style="padding:12px 16px; border:1px solid #333; color:#ddd;">
            ${detail}
          </td>
          <td style="padding:12px 16px; border:1px solid #333; text-align:center;">
            <span style="display:inline-block; padding:6px 12px; border:1px solid #333; background:${badgeColor}; color:#111; font-weight:bold; min-width:90px;">${badgeText}</span>
          </td>
        </tr>`;
    })
    .join('');

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>QUAKE:PKLAN:NET</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
  body {
    margin: 0;
    font-family: 'Verdana', 'Geneva', sans-serif;
    background-color: #000;
    color: #f9f9f9;
  }
  .wrapper {
    max-width: 960px;
    margin: 40px auto;
    padding: 16px;
    background: rgba(10, 10, 10, 0.85);
    border: 4px double #ffae00;
    box-shadow: 0 0 40px rgba(0,0,0,0.8);
    position: relative;
    z-index: 1;
  }
  .logo {
    text-align: center;
    margin-bottom: 12px;
  }
  .logo img {
    max-width: 220px;
    height: auto;
    display: inline-block;
  }
  .github-link {
    display: inline-block;
    vertical-align: middle;
    margin-left: 8px;
  }
  .github-link img {
    width: 20px;
    height: auto;
    display: inline-block;
    filter: drop-shadow(0 0 6px rgba(0,0,0,0.6));
    vertical-align: middle;
  }
  .footer {
    text-align: center;
    margin-top: 16px;
    padding-top: 12px;
    border-top: 1px solid rgba(255,174,0,0.08);
    color: #888;
    font-size: 12px;
  }
  h1 {
    font-size: 48px;
    text-align: center;
    letter-spacing: 6px;
    color: #ffae00;
    text-shadow: 0 0 12px rgba(255, 174, 0, 0.7);
    margin-bottom: 6px;
  }
  .subtitle {
    text-align: center;
    font-size: 12px;
    letter-spacing: 0.6em;
    color: #aaa;
    margin-bottom: 24px;
  }
  table {
    width: 100%;
    border-collapse: collapse;
  }
</style>
</head>
<body>
<div class="wrapper">
  <div class="logo"><img src="/logo.png" alt="QUAKE:PKLAN:NET logo"/></div>
  <h1>QUAKE:PKLAN:NET</h1>
  <div class="subtitle">THE PORTAL OF PERMANENT DEATH</div>
  <table>
    <tbody>
      ${rows}
    </tbody>
  </table>
  </div>
  <div class="footer">© ${year} <a href="https://github.com/humanstew" style="color:#ffdd57; text-decoration:none;">humanstew</a> — frag responsibly <a class="github-link" href="https://github.com/humanstew/ioq3-server" target="_blank" rel="noopener noreferrer"><img src="/github-mark.svg" alt="GitHub project" /></a></div>
</body>
<script>
  // no background/character script
</script>
</html>`;
}

app.get('/', async (_req, res) => {
  const statuses = await Promise.all(servers.map((server) => fetchStatus(server)));
  res.set('Cache-Control', 'no-store');
  res.send(renderHtml(statuses));
});

app.get('/status.json', async (_req, res) => {
  const statuses = await Promise.all(servers.map((server) => fetchStatus(server)));
  res.json(statuses);
});

app.listen(port, () => {
  console.log(`Landing page up on port ${port}`);
});
