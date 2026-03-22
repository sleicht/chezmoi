# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# `external-sync.zsh` handles FZF exports and compgen functions.
#
# Key binding ownership (configured in prompt.zsh):
#   Ctrl+T  → television (tv) — context-aware smart autocomplete
#   Ctrl+R  → atuin           — history search
#   Alt+C   → fzf             — directory cd
#   Tab     → fzf-tab         — shell completion
#   fzf-git → fzf             — git branch/commit/etc search
#   pj      → fzf             — project picker (Go binary)


# === fzf ===
# https://github.com/junegunn/fzf

# fzf configuration:
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type=d --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_OPTS="--preview '_fzf_complete_realpath {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"

# fzf-git configuration:
export FZF_GIT_COLOR='never'
export FZF_GIT_PREVIEW_COLOR='always'


# Use generator to customize:
# https://vitormv.github.io/fzf-themes/
# To add wrap lines add:
# --preview-window=wrap
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9,info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#ffb86c,header:#6272a4
--border=rounded
--preview-window=bottom,40%,border-rounded
--layout=reverse-list
--bind 'ctrl-a:toggle'
--bind 'ctrl-h:change-preview-window(hidden|)'
--cycle
-i
"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path () {
  fd --hidden --no-ignore-vcs --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir () {
  fd --type=d --hidden --no-ignore-vcs --exclude .git . "$1"
}

# See `.completions` file for all the list of fast tab completions.
