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
if [ -r "$HOMEBREW_PREFIX/opt/spaceship/spaceship.zsh" ]; then
  source "$HOMEBREW_PREFIX/opt/spaceship/spaceship.zsh"
fi

# Key binding load order (later wins):
#   fzf    → sets Ctrl+T, Alt+C, Ctrl+R
#   tv     → overwrites Ctrl+T (smart autocomplete), Ctrl+R
#   atuin  → overwrites Ctrl+R (history search), ^[[A (up-arrow history search)
#   keybinds.zsh → bindkey -e resets all to emacs defaults
#   forge  → overwrites ^M/^I (intercepts :commands and @completions)
# Result: Ctrl+T=tv, Alt+C=fzf, Ctrl+R=atuin, Up=atuin, Enter=forge→accept-line

# FZF keybindings: must be sync (Alt+C widget, fzf-tab base)
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"; fi
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"; fi

# Television keybindings: must be sync (Ctrl+T smart autocomplete)
if (( $+commands[tv] )); then
  eval "$(tv init zsh)"
fi

# Atuin keybindings: must be sync (Ctrl+R widget — overwrites tv's Ctrl+R)
source "$XDG_CONFIG_HOME/atuin/atuin-keybindings.zsh"

# NOTE: forge loads via forge.zsh (after keybinds.zsh in sheldon sync order)

preexec() { print '' }
