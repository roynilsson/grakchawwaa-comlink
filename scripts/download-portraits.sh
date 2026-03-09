#!/bin/bash
# Download all character and ship portrait images from the asset extractor
#
# Usage: ./download-portraits.sh [output-dir]
#
# Requires:
# - jq installed
# - Asset extractor running on localhost:3501
# - Comlink running on localhost:3500
# - units-clean.json file in ../data/

set -e

OUTPUT_DIR="${1:-./portraits}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
UNITS_FILE="${WORKSPACE_DIR}/data/units-clean.json"
COMLINK_URL="http://localhost:3500"
ASSET_URL="http://localhost:3501"

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install with: sudo apt install jq"
    exit 1
fi

if [ ! -f "$UNITS_FILE" ]; then
    echo "Error: Units file not found at $UNITS_FILE"
    echo "Run the unit data fetch script first."
    exit 1
fi

# Get asset version from comlink
echo "Fetching asset version from comlink..."
ASSET_VERSION=$(curl -s -X POST "$COMLINK_URL/metadata" \
    -H "Content-Type: application/json" \
    -d '{"payload":{}}' | jq -r '.assetVersion')

if [ -z "$ASSET_VERSION" ] || [ "$ASSET_VERSION" = "null" ]; then
    echo "Error: Could not get asset version. Is comlink running?"
    exit 1
fi

echo "Asset version: $ASSET_VERSION"

# Create output directories
mkdir -p "$OUTPUT_DIR/characters"
mkdir -p "$OUTPUT_DIR/ships"

# Download character portraits
echo ""
echo "Downloading character portraits..."
CHAR_COUNT=$(jq '.characters | length' "$UNITS_FILE")
echo "Total characters: $CHAR_COUNT"

i=0
jq -r '.characters[] | "\(.baseId)|\(.thumbnailName)"' "$UNITS_FILE" | while IFS='|' read -r base_id thumbnail; do
    i=$((i + 1))
    # Strip tex. prefix
    asset_name="${thumbnail#tex.}"
    output_file="$OUTPUT_DIR/characters/${base_id}.png"

    if [ -f "$output_file" ]; then
        echo "[$i/$CHAR_COUNT] Skipping $base_id (already exists)"
        continue
    fi

    echo "[$i/$CHAR_COUNT] Downloading $base_id..."
    curl -s "$ASSET_URL/Asset/single?version=$ASSET_VERSION&assetName=$asset_name" -o "$output_file"

    # Small delay to be nice to the server
    sleep 0.1
done

# Download ship portraits
echo ""
echo "Downloading ship portraits..."
SHIP_COUNT=$(jq '.ships | length' "$UNITS_FILE")
echo "Total ships: $SHIP_COUNT"

i=0
jq -r '.ships[] | "\(.baseId)|\(.thumbnailName)"' "$UNITS_FILE" | while IFS='|' read -r base_id thumbnail; do
    i=$((i + 1))
    # Strip tex. prefix
    asset_name="${thumbnail#tex.}"
    output_file="$OUTPUT_DIR/ships/${base_id}.png"

    if [ -f "$output_file" ]; then
        echo "[$i/$SHIP_COUNT] Skipping $base_id (already exists)"
        continue
    fi

    echo "[$i/$SHIP_COUNT] Downloading $base_id..."
    curl -s "$ASSET_URL/Asset/single?version=$ASSET_VERSION&assetName=$asset_name" -o "$output_file"

    # Small delay to be nice to the server
    sleep 0.1
done

echo ""
echo "Done! Portraits saved to $OUTPUT_DIR"
echo "  Characters: $(ls -1 "$OUTPUT_DIR/characters" | wc -l)"
echo "  Ships: $(ls -1 "$OUTPUT_DIR/ships" | wc -l)"
