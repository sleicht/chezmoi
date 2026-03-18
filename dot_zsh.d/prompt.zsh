#!/usr/bin/env zsh
# Prompt configuration - Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/

if [ -z "${HOMEBREW_PREFIX-}" ]; then
  if [ -d /opt/homebrew ]; then
    HOMEBREW_PREFIX=/opt/homebrew
  elif [ -d /home/linuxbrew/.linuxbrew ]; then
    HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
  else
    HOMEBREW_PREFIX=/usr/local
  fi
fi

# Prompt: must be sync (sets precmd hooks)
if (( $+commands[oh-my-posh] )); then
  # Invalidate evalcache when the oh-my-posh binary is upgraded
  local _omp_cache="$HOME/.zsh-evalcache/oh-my-posh.zsh"
  if [[ -f "$_omp_cache" && "$(command -v oh-my-posh)" -nt "$_omp_cache" ]]; then
    rm -f "$_omp_cache"
  fi
  _evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
fi

# Key binding load order (later wins):
#   fzf    → sets Ctrl+T, Alt+C, Ctrl+R
#   tv     → overwrites Ctrl+T (smart autocomplete), Ctrl+R
#   atuin  → overwrites Ctrl+R (history search)
# Result: Ctrl+T=tv, Alt+C=fzf, Ctrl+R=atuin

# FZF keybindings: must be sync (Alt+C widget, fzf-tab base)
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"; fi
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"; fi

# Television keybindings: must be sync (Ctrl+T smart autocomplete)
if (( $+commands[tv] )); then
  eval "$(tv init zsh)"
fi

# Atuin keybindings: must be sync (Ctrl+R widget — overwrites tv's Ctrl+R)
source "$XDG_CONFIG_HOME/atuin/atuin-keybindings.zsh"

preexec() { print '' }
