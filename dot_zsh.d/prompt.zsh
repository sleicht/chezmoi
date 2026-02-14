# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

if [ "$(uname -m)" = "x86_64" ]; then
  : "${HOMEBREW_PREFIX:=/usr/local}"
elif [ "$(uname -m)" = "arm64" ]; then
  : "${HOMEBREW_PREFIX:=/opt/homebrew}"
fi

# Prompt: must be sync (sets precmd hooks)
if (( $+commands[oh-my-posh] )); then
  _evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
fi

# FZF keybindings: must be sync (Ctrl+T, Alt+C widgets)
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"; fi
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"; fi

# Atuin keybindings: must be sync (Ctrl+R widget)
source "$XDG_CONFIG_HOME/atuin/atuin-keybindings.zsh"

preexec() { print '' }
