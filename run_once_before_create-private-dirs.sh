#!/bin/bash
# Create optional private ZSH config directory
# antidote sources *.zsh files from here via ~/.zsh.d/private-sync.zsh

mkdir -p "$HOME/.zsh.d.private"
if [ "$(uname -s)" = "Darwin" ]; then
  mkdir -p "$HOME/Applications"
fi
