# Grakchawwaa Comlink - SWGOH Game Data Proxy

Docker-based wrapper around [swgoh-comlink](https://github.com/swgoh-utils/swgoh-comlink) providing live SWGOH game data.

## Overview

This service provides a REST API to fetch live game data from SWGOH servers:
- Player profiles by ally code
- Guild rosters and member data
- Game metadata (version, assets)
- Character/ship portrait images

Used by the backend for ticket checks, guild sync, and unit data.

## Services

| Service | Port | Description |
|---------|------|-------------|
| Comlink | 3500 | SWGOH game data API (players, guilds, metadata) |
| Asset Extractor | 3501 | Character/ship portrait images |

## Quick Start

```bash
# Start services
docker compose up -d

# Check health
curl http://localhost:3500/metadata -X POST -H "Content-Type: application/json" -d '{"payload":{}}'
```

## API Examples

### Get Metadata

```bash
curl -X POST http://localhost:3500/metadata \
  -H "Content-Type: application/json" \
  -d '{"payload":{}}'
```

Returns game version and asset version.

### Get Player by Ally Code

```bash
curl -X POST http://localhost:3500/player \
  -H "Content-Type: application/json" \
  -d '{"payload":{"allyCode":"123456789"}}'
```

Returns player profile including roster, stats, and guild membership.

### Get Guild

```bash
curl -X POST http://localhost:3500/guild \
  -H "Content-Type: application/json" \
  -d '{"payload":{"guildId":"GUILD_ID_HERE","includeRecentGuildActivityInfo":true}}'
```

Returns guild info including members and activity.

### Get Game Data (Characters, Ships, etc.)

```bash
# Get current game data version first
VERSION=$(curl -s -X POST http://localhost:3500/metadata \
  -H "Content-Type: application/json" \
  -d '{"payload":{}}' | jq -r '.latestGamedataVersion')

# Fetch game data
curl -X POST http://localhost:3500/data \
  -H "Content-Type: application/json" \
  -d "{\"payload\":{\"version\":\"$VERSION\",\"includePveUnits\":false}}"
```

### Get Character Portrait (Asset Extractor)

```bash
# Get asset version from metadata
ASSET_VERSION=$(curl -s -X POST http://localhost:3500/metadata \
  -H "Content-Type: application/json" \
  -d '{"payload":{}}' | jq -r '.assetVersion')

# Fetch portrait (128x128 PNG)
curl "http://localhost:3501/Asset/single?version=${ASSET_VERSION}&assetName=charui_vader" -o vader.png
```

**Asset naming:** Strip the `tex.` prefix from the game's `thumbnailName` field:
- `tex.charui_vader` -> `charui_vader`
- `tex.charui_chimaera` -> `charui_chimaera`

Swagger docs: http://localhost:3501/swagger

## Docker Configuration

```yaml
services:
  comlink:
    build: .
    ports:
      - "3500:3000"
    environment:
      - APP_NAME=grakchawwaa-comlink
    networks:
      - grakchawwaa-network

  asset-extractor:
    image: ghcr.io/swgoh-utils/swgoh-asset-extractor:latest
    ports:
      - "3501:3000"
    networks:
      - grakchawwaa-network

networks:
  grakchawwaa-network:
    external: true
```

## Network Integration

All Grakchawwaa services share `grakchawwaa-network`:
- Backend connects to `http://grakchawwaa-comlink:3000` (internal)
- Host access available at `http://localhost:3500`

Create the network if it doesn't exist:

```bash
docker network create grakchawwaa-network
```

## Production Deployment (Heroku)

The service is deployed to Heroku via GitHub Actions.

### Initial Setup

1. Get your Heroku API Key from https://dashboard.heroku.com/account
2. Add to GitHub Secrets: **Settings > Secrets > Actions > New secret**
   - Name: `HEROKU_API_KEY`
   - Value: Your API key

### Automatic Deployment

- Pushes to `main` trigger automatic deployment
- Manual trigger available from GitHub **Actions** tab

### Heroku App

```bash
# Open deployed app
heroku open -a grakchawwaa-swgoh-comlink

# Set config vars
heroku config:set VAR_NAME=value -a grakchawwaa-swgoh-comlink

# View logs
heroku logs -t -a grakchawwaa-swgoh-comlink
```

## Nginx Configuration (Optional)

For public access with SSL, an nginx config is provided:

```bash
# Location: nginx/nginx.conf
# Domain: comlink.grakchawwaa.com
# Features: SSL, 120s timeout, 50M body size
```

## Related Projects

- **grakchawwaa-backend** - REST API (primary consumer)
- **grakchawwaa-bot** - Discord bot
- **grakchawwaa-web** - Web dashboard

## License

MIT
