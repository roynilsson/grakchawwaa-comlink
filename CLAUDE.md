# CLAUDE.md - grakchawwaa-comlink

SWGOH game data proxy. Docker wrapper around swgoh-comlink binary.

## Quick Reference

```bash
# Development
docker compose up -d              # Start comlink + asset extractor
docker compose logs -f comlink    # View logs
docker compose restart comlink    # Restart after changes

# Test endpoints
curl -X POST http://localhost:3500/metadata -H "Content-Type: application/json" -d '{"payload":{}}'
```

## Services

| Service | Host Port | Container Port | Description |
|---------|-----------|----------------|-------------|
| Comlink | 3500 | 3000 | SWGOH game data API |
| Asset Extractor | 3501 | 3000 | Character/ship portraits |

## Project Structure

```
grakchawwaa-comlink/
├── Dockerfile              # Comlink binary setup
├── docker-compose.yml      # Service definitions
├── nginx/
│   └── nginx.conf          # Production nginx config (optional)
└── README.md
```

## Key Endpoints

### Comlink (port 3500)

| Endpoint | Description |
|----------|-------------|
| `POST /metadata` | Game and asset versions |
| `POST /player` | Player profile by ally code |
| `POST /guild` | Guild data by guild ID |
| `POST /data` | Game data (characters, ships, abilities) |

### Asset Extractor (port 3501)

| Endpoint | Description |
|----------|-------------|
| `GET /Asset/single?version=X&assetName=Y` | Character/ship portrait |
| `GET /swagger` | API documentation |

## Network

All services connect to `grakchawwaa-network`:
- Backend uses `http://grakchawwaa-comlink:3000` (internal)
- Host access at `http://localhost:3500`

```bash
# Create network if needed
docker network create grakchawwaa-network
```

## Common Tasks

### Fetch Player Data
```bash
curl -X POST http://localhost:3500/player \
  -H "Content-Type: application/json" \
  -d '{"payload":{"allyCode":"123456789"}}'
```

### Fetch Game Data
```bash
# Get version first
VERSION=$(curl -s -X POST http://localhost:3500/metadata \
  -H "Content-Type: application/json" \
  -d '{"payload":{}}' | jq -r '.latestGamedataVersion')

# Fetch data
curl -X POST http://localhost:3500/data \
  -H "Content-Type: application/json" \
  -d "{\"payload\":{\"version\":\"$VERSION\",\"includePveUnits\":false}}"
```

## Deployment

Deployed to Heroku via GitHub Actions on push to `main`.

## Reference

- [swgoh-comlink](https://github.com/swgoh-utils/swgoh-comlink) - Upstream project
- [swgoh-asset-extractor](https://github.com/swgoh-utils/swgoh-asset-extractor) - Portrait images
