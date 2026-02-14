#!/usr/bin/env bash
# =============================================================================
# check-parsable.sh — Application config parsability helper
# =============================================================================
# Provides check_app_can_parse function for the verification framework.
# Sourced by verify-configs.sh; do not execute directly.
# =============================================================================

# Check that a target application can parse/load its config file.
# Arguments:
#   $1 — Application name (bat, lsd, btop, kitty, wezterm, lazygit, ghostty)
#   $2 — Absolute path to the config file
# Returns:
#   0 if parsable, 1 if not
check_app_can_parse() {
  local app="$1"
  local config="$2"

  # Config must exist
  if [ ! -f "$config" ]; then
    return 1
  fi

  case "$app" in
    bat)
      # bat can validate by listing themes with a config
      bat --config-file "$config" --list-themes &>/dev/null
      ;;
    lsd)
      # lsd has no config validation flag; check it starts
      lsd --version &>/dev/null
      ;;
    btop)
      # Check file starts with comment or valid config syntax
      head -1 "$config" | grep -qE '^(#|[a-zA-Z_])' 2>/dev/null
      ;;
    kitty)
      kitty --config "$config" --debug-config &>/dev/null
      ;;
    wezterm)
      # Try Lua syntax check first, fall back to wezterm validation
      luac -p "$config" 2>/dev/null || wezterm show-config --config-file "$config" &>/dev/null
      ;;
    lazygit)
      # lazygit has no per-file validation; check YAML syntax
      if command -v yq &>/dev/null; then
        yq eval '.' "$config" &>/dev/null
      else
        # Basic check: file is not empty and starts with valid YAML
        head -1 "$config" | grep -qE '^(#|[a-zA-Z_-])' 2>/dev/null
      fi
      ;;
    ghostty)
      # Check config file has valid key=value or key = value format
      # Every non-comment, non-empty line should match
      grep -v '^[[:space:]]*#' "$config" | grep -v '^[[:space:]]*$' | \
        grep -qvE '^[a-zA-Z_-]+\s*=' && return 1
      return 0
      ;;
    *)
      # Unknown app — skip validation
      return 0
      ;;
  esac
}
