#!/usr/bin/env bash
# =============================================================================
# check-exists.sh — File existence check helper
# =============================================================================
# Provides check_file_exists function for the verification framework.
# Sourced by verify-configs.sh; do not execute directly.
# =============================================================================

# Check if a file or directory exists at the given path.
# Arguments:
#   $1 — Absolute path to check
# Returns:
#   0 if exists, 1 if not
check_file_exists() {
  local path="$1"
  [ -e "$path" ]
}
