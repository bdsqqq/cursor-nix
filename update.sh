#!/usr/bin/env bash
set -euo pipefail

APT_PACKAGES_URL="https://downloads.cursor.com/aptrepo/dists/stable/main/binary-amd64/Packages"
PACKAGE_NIX="$(dirname "$0")/package.nix"

echo "Fetching apt Packages metadata..."
PACKAGES_DATA=$(curl -fsSL "$APT_PACKAGES_URL") || { echo "Failed to fetch apt metadata"; exit 1; }

# apt Packages file has both cursor and cursor-nightly; we want stable
get_field() {
    local pkg_data="$1"
    local field="$2"
    local value
    value=$(echo "$pkg_data" | grep -E "^${field}:" | head -1 | sed "s/^${field}: //")
    if [ -z "$value" ]; then
        echo "ERROR: Missing required field: $field" >&2
        exit 1
    fi
    echo "$value"
}

CURSOR_BLOCK=$(echo "$PACKAGES_DATA" | awk '/^Package: cursor$/,/^$/')

if [ -z "$CURSOR_BLOCK" ]; then
    echo "ERROR: Could not find cursor package block in apt metadata"
    exit 1
fi

LATEST_VERSION=$(get_field "$CURSOR_BLOCK" "Version")
LATEST_SHA256=$(get_field "$CURSOR_BLOCK" "SHA256")
LATEST_FILENAME=$(get_field "$CURSOR_BLOCK" "Filename")

# apt Version includes build number (2.2.44-1766613274) but Filename uses base version only
DISPLAY_VERSION=$(echo "$LATEST_VERSION" | sed 's/-[0-9]*$//')

echo "Latest version: $DISPLAY_VERSION (full: $LATEST_VERSION)"
echo "SHA256: $LATEST_SHA256"
echo "Filename: $LATEST_FILENAME"

CURRENT_VERSION=$(grep -E '^\s*version = "' "$PACKAGE_NIX" | sed 's/.*version = "\([^"]*\)".*/\1/')
echo "Current version: $CURRENT_VERSION"

if [ "$DISPLAY_VERSION" = "$CURRENT_VERSION" ]; then
    echo "Already up to date!"
    exit 0
fi

echo "Updating package.nix..."

sed -i "s/version = \"[^\"]*\"/version = \"$DISPLAY_VERSION\"/" "$PACKAGE_NIX"
sed -i "s/sha256 = \"[^\"]*\"/sha256 = \"$LATEST_SHA256\"/" "$PACKAGE_NIX"
sed -i "s|upstreamFilename = \"[^\"]*\"|upstreamFilename = \"$LATEST_FILENAME\"|" "$PACKAGE_NIX"

echo "Updated $CURRENT_VERSION -> $DISPLAY_VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "updated=true" >> "$GITHUB_OUTPUT"
    echo "old_version=$CURRENT_VERSION" >> "$GITHUB_OUTPUT"
    echo "new_version=$DISPLAY_VERSION" >> "$GITHUB_OUTPUT"
fi
