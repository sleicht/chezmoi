#!/usr/bin/env zsh
# shellcheck shell=bash
# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/

# Interactive-shell variables only. POSIX-portable env vars live in ~/.profile.

# === Editor / Pager ===
export EDITOR="subl -w"

#   -i   smart case-insensitive search
#   -R   colour
#   -F   exit if less than one page
#   -X   keep content on screen after exit
#   -M   verbose prompt
#   -x4  4-space tabs
#   --mouse  mouse scrolling
export LESS='-iRFXMx4 --mouse'
export PAGER='less'
export MANPAGER='less -X'

# Highlight section titles in manual pages (bold yellow)
LESS_TERMCAP_md=$(printf '\033[1;33m')
export LESS_TERMCAP_md

# === Tools ===
export BAT_THEME="Dracula"
GPG_TTY="$(tty)"
export GPG_TTY

# === Node REPL ===
export NODE_REPL_HISTORY="$HOME/.node_history"
export NODE_REPL_HISTORY_SIZE='32768'
export NODE_REPL_MODE='sloppy'

# === Erlang ===
export ERL_AFLAGS='-kernel shell_history enabled'

# === Misc ===
export BASH_SILENCE_DEPRECATION_WARNING=1
export OPENCODE_EXPERIMENTAL_FILEWATCHER=true
export OPENCODE_EXPERIMENTAL_ICON_DISCOVERY=true
export OPENCODE_EXPERIMENTAL_LSP_TOOL=true

# === zsh-syntax-highlighting ===
# https://github.com/zsh-users/zsh-syntax-highlighting
# We won't highlight code longer than 200 chars, because it is slow:
export ZSH_HIGHLIGHT_MAXLENGTH=200
