#!/usr/bin/env bash
# =============================================================================
# check-valid.sh — Template error detection helper
# =============================================================================
# Provides check_no_template_errors function for the verification framework.
# Sourced by verify-configs.sh; do not execute directly.
# =============================================================================

# Check that a deployed config file has no unprocessed chezmoi template markers
# or error placeholders.
# Arguments:
#   $1 — Absolute path to the deployed config file
# Returns:
#   0 if valid, 1 if template errors detected
check_no_template_errors() {
  local path="$1"

  # File must exist
  if [ ! -f "$path" ]; then
    return 1
  fi

  # File should not be empty (unless explicitly expected)
  if [ ! -s "$path" ]; then
    return 1
  fi

  # Check for unprocessed Go template markers ({{ }})
  # Exclude comments (lines starting with #) and documentation
  if grep -v '^[[:space:]]*#' "$path" | grep -qE '\{\{[^}]*\}\}'; then
    return 1
  fi

  # Check for TEMPLATE_ERROR placeholder strings
  if grep -qi 'TEMPLATE_ERROR' "$path"; then
    return 1
  fi

  return 0
}
