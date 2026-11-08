#!/usr/bin/env bash
# Fetches the libraries listed in .pkgmeta into Libs/ for local development.
# The release packager fetches its own copy; Libs/ is git-ignored.
set -euo pipefail

ACE3_REPO="https://github.com/WoWUIDev/Ace3.git"
ACE3_REF="${ACE3_REF:-Release-r981}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --quiet --depth 1 --branch "$ACE3_REF" "$ACE3_REPO" "$TMP/Ace3"

mkdir -p "$ROOT/Libs"
for lib in LibStub CallbackHandler-1.0 AceDB-3.0; do
  rm -rf "${ROOT:?}/Libs/$lib"
  cp -R "$TMP/Ace3/$lib" "$ROOT/Libs/$lib"
done

echo "Libs fetched from $ACE3_REPO@$ACE3_REF"
