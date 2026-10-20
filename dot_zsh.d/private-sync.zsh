#!/usr/bin/env zsh
# Expand at runtime so new private files need no static bundle rebuild.
() {
  local file
  for file in "$HOME"/.zsh.d.private/*.zsh(N); do
    source "$file"
  done
}
