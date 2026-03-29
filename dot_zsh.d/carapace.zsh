# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# === multi-shell multi-command argument complete ===
if (( $+commands[carapace] )); then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  # shellcheck disable=SC1090
  _evalcache carapace _carapace

  # Ensure fzf-tab shows carapace group descriptions
  zstyle ':fzf-tab:*' show-group full
  zstyle ':fzf-tab:*' group-colors $'\033[33m' $'\033[35m' $'\033[32m' $'\033[36m' $'\033[31m' $'\033[34m'
fi
