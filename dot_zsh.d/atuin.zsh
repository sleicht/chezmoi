# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# === Advanced History ===
if (( $+commands[atuin] )); then
#  export ATUIN_NOBIND="true"
  _evalcache atuin init zsh
fi
