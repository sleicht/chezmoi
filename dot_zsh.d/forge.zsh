#!/usr/bin/env zsh
# Forge shell integration - Managed by chezmoi
# Must load AFTER keybinds.zsh (bindkey -e resets all bindings)
if (( $+commands[forge] )); then
  # Guard relies on forge's own $_FORGE_PLUGIN_LOADED env var set by `forge zsh plugin`.
  # If forge stops setting it, the eval becomes a harmless no-op (idempotent).
  if [[ -z "$_FORGE_PLUGIN_LOADED" ]]; then
    eval "$(forge zsh plugin)"
  fi

  # Forge AI context in Spaceship's right prompt. The section is async, so a
  # slow Forge response should not block the primary prompt render.
  SPACESHIP_RPROMPT_ORDER=(forge)
  SPACESHIP_FORGE_SHOW="${SPACESHIP_FORGE_SHOW=true}"
  SPACESHIP_FORGE_ASYNC="${SPACESHIP_FORGE_ASYNC=true}"
  SPACESHIP_FORGE_PREFIX="${SPACESHIP_FORGE_PREFIX=""}"
  SPACESHIP_FORGE_SUFFIX="${SPACESHIP_FORGE_SUFFIX=""}"

  spaceship_forge() {
    [[ "$SPACESHIP_FORGE_SHOW" == false ]] && return
    (( $+commands[forge] )) || return

    local forge_rprompt
    forge_rprompt="$(
      _FORGE_CONVERSATION_ID="$_FORGE_CONVERSATION_ID" \
      _FORGE_ACTIVE_AGENT="$_FORGE_ACTIVE_AGENT" \
      "${_FORGE_BIN:-forge}" zsh rprompt
    )"
    [[ -n "$forge_rprompt" ]] || return

    spaceship::section::v4 \
      --prefix "$SPACESHIP_FORGE_PREFIX" \
      --suffix "$SPACESHIP_FORGE_SUFFIX" \
      "$forge_rprompt"
  }
fi
