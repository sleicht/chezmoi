# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

if [ "$(uname -m)" = "x86_64" ]; then
  : "${HOMEBREW_PREFIX:=/usr/local}"
elif [ "$(uname -m)" = "arm64" ]; then
  : "${HOMEBREW_PREFIX:=/opt/homebrew}"
fi

#: "${XDG_DATA_HOME:=$HOME/.local/share}"
#: "${RUSTUP_HOME:=$XDG_DATA_HOME/rustup}"

#FPATH="/run/current-system/sw/share/zsh/zsh-abbr":$FPATH
#FPATH="$HOMEBREW_PREFIX/share/zsh-abbr":$FPATH
#fpath=("$RUSTUP_HOME" "$HOMEBREW_PREFIX/opt/zsh-completions/share/zsh-completions" $fpath)

autoload -Uz colors
colors

autoload -Uz select-word-style
select-word-style default

zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

autoload predict-on
zle -N predict-on
zle -N predict-off
zstyle ':predict' verbose true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z} r:|[-_.]=**'
zstyle ':completion:*' completer _complete _ignored _cmdstring _canonical_paths _expand _extensions _external_pwds _expand_alias _files _multi_parts
if [ -n "$LS_COLORS" ]; then
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
else
  zstyle ':completion:*' list-colors ''
fi
zstyle ':completion:*:cd:*' tag-order local-directories path-directories
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:sudo:*' command-path $HOMEBREW_PREFIX/sbin $HOMEBREW_PREFIX/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# === fzf-tab ===
# Switch fzf-tab completion to use tmux popup if available, otherwise standard
zstyle ':fzf-tab:*' fzf-flags --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9,info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#ffb86c,header:#6272a4
# Use the same group colouring for completion groups
zstyle ':fzf-tab:*' switch-group '<' '>'

# Default fallback preview for any completion (FZFT-01: file preview with bat)
zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --theme=Dracula --number --line-range :100 -- ${(Q)realpath} 2>/dev/null || echo ${(Q)realpath}'

# Directory preview (FZFT-02: eza tree for directories)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --icons --color=always -- ${(Q)realpath} 2>/dev/null'
zstyle ':fzf-tab:complete:pushd:*' fzf-preview 'eza --tree --level=2 --icons --color=always -- ${(Q)realpath} 2>/dev/null'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza --tree --level=2 --icons --color=always -- ${(Q)realpath} 2>/dev/null'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza --tree --level=2 --icons --color=always -- ${(Q)realpath} 2>/dev/null || bat --color=always --theme=Dracula --number --line-range :100 -- ${(Q)realpath} 2>/dev/null'

# Process preview for kill (FZFT-03: show process info)
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -p $word -o pid,ppid,user,%cpu,%mem,start,time,command 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview-window='bottom,40%,border-rounded,wrap'

# Environment variable preview (FZFT-04: show env var values)
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word} | head -c 200'

# Git log preview for branch completions (FZFT-05: oneline format with graph per user decision)
zstyle ':fzf-tab:complete:git-(checkout|switch|merge|rebase|branch):*' fzf-preview 'git log --oneline --graph --color=always --decorate $word 2>/dev/null | head -50'

# Git log preview for commit hash completions (FZFT-06: log/show/reset/revert/cherry-pick)
zstyle ':fzf-tab:complete:git-(log|show|reset|revert|cherry-pick):*' fzf-preview 'git log --oneline --graph --color=always --decorate $word 2>/dev/null | head -50'

# Git diff preview for add/stage completions
zstyle ':fzf-tab:complete:git-(add|stage|diff|restore):*' fzf-preview 'git diff --color=always -- $word 2>/dev/null | head -100'

# Preview window defaults for fzf-tab
zstyle ':fzf-tab:*' fzf-pad 4
