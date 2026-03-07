# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/

# === worktrunk ===
# Initialises worktrunk's shell integration (aliases, hooks, env vars).
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
