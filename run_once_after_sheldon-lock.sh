#!/bin/bash
# Build sheldon plugin lock file on first apply
set -e

if ! command -v sheldon > /dev/null; then
  echo "WARNING: sheldon not found, skipping plugin lock"
  exit 0
fi

echo "==> Building sheldon plugin lock..."
sheldon lock --update
echo "==> Sheldon plugin lock complete."
