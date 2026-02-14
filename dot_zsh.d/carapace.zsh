# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# === multi-shell multi-command argument complete ===
if (( $+commands[carapace] )); then
  export CARAPACE_BRIDGES='bat,zsh,fish,bash,inshellisense,tofu' # optional
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  # shellcheck disable=SC1090
  source <(carapace _carapace)
fi
