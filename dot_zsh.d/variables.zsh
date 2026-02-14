# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh
# shellcheck disable=SC2154

# `variables.zsh` is used to provide custom variables.

# === Dotfiles location ===
export DOTFILES="${HOME}/.dotfiles"

# === bat ===
# https://github.com/sharkdp/bat
export BAT_THEME="Dracula"

# === Compiler flags ===

# This is required because `openssl` is keg-only in `brew`,
# see: `brew info openssl` for more information.
export LDFLAGS="-L$(brew --prefix)/opt/openssl/lib"
export CPPFLAGS="-I$(brew --prefix)/opt/openssl/include"
#export CFLAGS="-I$(xcrun --show-sdk-path)/usr/include"
export PKG_CONFIG_PATH="$(brew --prefix)/opt/openssl/lib/pkgconfig"


# === Path modifications ===
# These lines should be the first ones!

# GPG agent:
PATH="/usr/local/opt/gpg-agent/bin:$PATH"

export GEM_HOME=$HOME/.gem
PATH=$GEM_HOME/bin:$PATH

# === General ===
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

if [ "$(uname -m)" = "x86_64" ]; then
  export ARCHFLAGS="-arch x86_64"
  export HOMEBREW_PREFIX="/usr/local"
  export HOMEBREW_CELLAR="/usr/local/Cellar"
  export HOMEBREW_REPOSITORY="/usr/local/Homebrew"

  export BUNDLE_USER_HOME="$XDG_DATA_HOME/bundle/x86_64"
  export BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME/bundle/x86_64/config"
  export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle/x86_64"
  export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle/x86_64/plugin"
elif [ "$(uname -m)" = "arm64" ]; then
  export ARCHFLAGS="-arch arm64"
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"

  export BUNDLE_USER_HOME="$XDG_DATA_HOME/bundle/arm64"
  export BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME/bundle/arm64/config"
  export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle/arm64"
  export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle/arm64/plugin"
fi

#export CPU_BRAND="$(/usr/sbin/sysctl -n machdep.cpu.brand_string)"
#export X86_64_HOMEBREW_PATH="/usr/local/bin/brew"

# Make Sublime Text the default editor
export EDITOR="subl -w"

# GPG:
export GPG_TTY="$(tty)"
eval "$(gpg-agent --daemon --allow-preset-passphrase > /dev/null 2>&1)"

# Homebrew:
export HOMEBREW_NO_ANALYTICS=1  # disables statistics that brew collects

# Pagers:
# This affects every invocation of `less`.
#
#   -i       smart case-insensitive search
#   -R       color
#   -F       exit if there is less than one page of content
#   -X       keep content on screen after exit
#   -M       show more info at the bottom prompt line
#   -x4      tabs are 4 instead of 8
#   --mouse  mouse support for scrolling
export LESS='-iRFXMx4 --mouse'
export PAGER='less'
# I don't use `bat` here, because I don't like the highlight.
# sh -c 'col -b | bat -l man -p --theme="$BAT_THEME"'
export MANPAGER='less'

# === Histories ===
# Enable persistent REPL history for `node`.
export NODE_REPL_HISTORY="$HOME/.node_history"
# Allow 32³ entries; the default is 1000.
export NODE_REPL_HISTORY_SIZE='32768';
# Use sloppy mode by default, matching web browsers.
export NODE_REPL_MODE='sloppy'

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING='UTF-8'

# Increase Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE=32768
export SAVEHIST=32768
export HISTFILESIZE="${HISTSIZE}"
# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth'
# Make some commands not show up in history
#export HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"
export HISTIGNORE="history:cd:pwd:exit:date:* --help"
export HISTFILE=~/.zsh_history

# Prefer US English and use UTF-8.
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}"

# Don’t clear the screen after quitting a manual page.
export MANPAGER='less -X'

# Hide the "default interactive shell is now zsh" warning on macOS.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Erlang and Elixir shell history:
export ERL_AFLAGS='-kernel shell_history enabled'


# === OpenCode ===
export OPENCODE_EXPERIMENTAL_FILEWATCHER=true
export OPENCODE_EXPERIMENTAL_ICON_DISCOVERY=true
export OPENCODE_EXPERIMENTAL_LSP_TOOL=true

# === Code highlight ===
# https://github.com/zsh-users/zsh-syntax-highlighting

# We won't highlight code longer than 200 chars, because it is slow:
export ZSH_HIGHLIGHT_MAXLENGTH=200

# === PATH ===
# This should be the last line:
export PATH
