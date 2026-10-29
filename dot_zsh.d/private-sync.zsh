#!/usr/bin/env zsh
# Expand at runtime so new private files need no static bundle rebuild.
() {
  local plugins_file="$HOME/.zsh.d.private/plugins.txt"
  if [[ -r "$plugins_file" && -s "$plugins_file" ]]; then
    antidote load "$plugins_file" "$HOME/.zsh_plugins.private.zsh"
  fi

  local file
  for file in "$HOME"/.zsh.d.private/*.zsh(N); do
    source "$file"
  done
}
