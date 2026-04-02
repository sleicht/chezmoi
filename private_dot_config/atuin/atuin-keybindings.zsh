#!/usr/bin/env zsh

if command -v atuin > /dev/null; then
  bindkey '^r' atuin-search
  bindkey -M emacs '^R' atuin-search
  bindkey '^[[A' atuin-up-search
  bindkey -M emacs '^[[A' atuin-up-search
fi
