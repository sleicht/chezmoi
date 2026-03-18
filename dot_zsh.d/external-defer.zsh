#!/usr/bin/env zsh
# Deferred external tool initialisation - Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/

# === z ===
# https://github.com/ajeetdsouza/zoxide
# `zoxide` has an option to use `fzf` to provide completions natively,
# but it works only for `z NAME<SPACE><TAB>`,
# it does not work for `z NAME<TAB>`.
# So, I have this usecase as a custom completion defined in `.completions`.
if (( $+commands[zoxide] )); then
  _evalcache zoxide init zsh --no-cmd
fi

z() {
  # I need this function to setup custom code completion for `zoxide`.
  \__zoxide_z "$@"
}

# === mise ===
# https://mise.jdx.dev/
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi
