# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# === IntelliShell ===
if (( $+commands[intelli-shell] )); then
  _evalcache intelli-shell init zsh
fi
