#!/usr/bin/env zsh

if command -v atuin > /dev/null; then
  bindkey '^r' atuin-search
  bindkey -M emacs '^R' atuin-search
fi
