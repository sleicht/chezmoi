#!/usr/bin/env zsh
# Deferred completions - Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/

_cache_hosts=()
if [[ -r $HOME/.ssh/config ]]; then
  _cache_hosts=(${${${(M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# phantom completions (requires working node runtime)
if (( $+commands[phantom] )); then
  eval "$(phantom completion zsh 2>/dev/null)" || true
fi
