#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-18-latest}"
REPO="https://github.com/pganalyze/libpg_query.git"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/../libs"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Cloning libpg_query ($BRANCH)..."
git clone -b "$BRANCH" --depth 1 "$REPO" "$tmpdir/libpg_query"

echo "Building libpg_query.a (this may take a few minutes)..."
make -C "$tmpdir/libpg_query" -j"$(nproc)"

echo "Copying files to libs/..."
cp "$tmpdir/libpg_query/libpg_query.a" "$LIBS_DIR/"
cp "$tmpdir/libpg_query/pg_query.h" "$LIBS_DIR/"
cp "$tmpdir/libpg_query/postgres_deparse.h" "$LIBS_DIR/"

VERSION=$(grep '#define PG_VERSION ' "$LIBS_DIR/pg_query.h" | awk '{print $3}' | tr -d '"')
echo "Done. libpg_query $VERSION ($BRANCH) installed to libs/"
