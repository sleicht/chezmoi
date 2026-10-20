#!/usr/bin/env zsh
# Initialise completion synchronously before fzf-tab is queued.
autoload -Uz compinit
if [[ -f "${ZDOTDIR:-$HOME}/.zcompdump" ]]; then
  compinit -C
else
  compinit
fi
