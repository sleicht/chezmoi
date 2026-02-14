# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

bindkey -e

bindkey '' predict-on
bindkey '' predict-off
bindkey '^[R' history-incremental-pattern-search-backward
bindkey '^[S' history-incremental-pattern-search-forward
bindkey "^[u" undo
bindkey "^[r" redo

bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

if (( $+commands[abbr] )); then
  bindkey '^X' abbr-expand
  bindkey '^[ ' magic-space
fi
