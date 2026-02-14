# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

if [ "$(uname -m)" = "x86_64" ]; then
  : "${HOMEBREW_PREFIX:=/usr/local}"
elif [ "$(uname -m)" = "arm64" ]; then
  : "${HOMEBREW_PREFIX:=/opt/homebrew}"
fi

#if command -v direnv > /dev/null; then eval "$(direnv hook zsh)"; fi
if (( $+commands[oh-my-posh] )); then eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"; fi

: "${REPOSITORIES_PATH:=$HOME/Repositories}"
: "${GITHUB_REPOSITORIES_PATH=$REPOSITORIES_PATH/github.com}"

if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"; fi
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"; fi
source "$XDG_CONFIG_HOME/atuin/atuin-keybindings.zsh"

#if [ -r "$GITHUB_REPOSITORIES_PATH/seebi/dircolors-solarized/dircolors.ansi-universal" ]; then eval $(gdircolors "$GITHUB_REPOSITORIES_PATH/seebi/dircolors-solarized/dircolors.ansi-universal"); fi

preexec() { print '' }

unset GITHUB_REPOSITORIES_PATH
unset REPOSITORIES_PATH
