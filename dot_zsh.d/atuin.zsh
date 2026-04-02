#!/usr/bin/env zsh
# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/

# === Advanced History ===
if (( $+commands[atuin] )); then
  export ATUIN_NOBIND="true"
  # Invalidate evalcache when NOBIND changes (cache was built without it)
  local _atuin_cache="$HOME/.zsh-evalcache/atuin.zsh"
  if [[ -f "$_atuin_cache" ]] && grep -q 'accept-line' "$_atuin_cache"; then
    rm -f "$_atuin_cache"
  fi
  _evalcache atuin init zsh
fi
