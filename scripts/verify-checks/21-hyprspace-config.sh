# shellcheck shell=bash
# =============================================================================
# 21-hyprspace-config.sh — Hyprspace source configuration invariants
# =============================================================================
# Sourced by verify-configs.sh; do not execute directly.
# =============================================================================

HYPRSPACE_CONFIG_SOURCE="$SCRIPT_DIR/../private_dot_config/hyprspace/config.toml.tmpl"

[ -f "$HYPRSPACE_CONFIG_SOURCE" ] || return 1

rg -Fqx "alt-b = 'new-window-or-open \"Google Chrome\"'" "$HYPRSPACE_CONFIG_SOURCE"
