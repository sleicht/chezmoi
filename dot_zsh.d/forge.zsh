#!/usr/bin/env zsh
# Forge shell integration - Managed by chezmoi
# Must load AFTER keybinds.zsh (bindkey -e resets all bindings)
if (( $+commands[forge] )); then
  # Guard relies on forge's own $_FORGE_PLUGIN_LOADED env var set by `forge zsh plugin`.
  # If forge stops setting it, the eval becomes a harmless no-op (idempotent).
  if [[ -z "$_FORGE_PLUGIN_LOADED" ]]; then
    eval "$(forge zsh plugin)"
  fi
  # Forge AI context in RPROMPT (runs `forge zsh rprompt` on every prompt;
  # ensure the binary starts in <10ms to avoid visible latency).
  # oh-my-posh clears RPROMPT via eval on every precmd cycle, so we must
  # set it AFTER omp runs. We wrap _omp_precmd on first prompt render
  # (deferred because _omp_precmd may not be defined at source time).
  function _forge_rprompt_precmd() {
    if (( $+functions[_omp_precmd] )) && ! (( $+functions[_omp_precmd_orig] )); then
      functions[_omp_precmd_orig]="$functions[_omp_precmd]"
      function _omp_precmd() {
        _omp_precmd_orig
        RPROMPT="$(_FORGE_CONVERSATION_ID=$_FORGE_CONVERSATION_ID \
          _FORGE_ACTIVE_AGENT=$_FORGE_ACTIVE_AGENT \
          "${_FORGE_BIN:-forge}" zsh rprompt)"
      }
      # Run the wrapped version immediately for this first render
      _omp_precmd
    elif ! (( $+functions[_omp_precmd] )); then
      # No oh-my-posh — set RPROMPT directly
      RPROMPT="$("${_FORGE_BIN:-forge}" zsh rprompt)"
    fi
    # else: already wrapped, _omp_precmd handles it
  }
  # Guard against duplicate entries when .zshrc is re-sourced
  if (( ! ${precmd_functions[(Ie)_forge_rprompt_precmd]:-0} )); then
    precmd_functions+=(_forge_rprompt_precmd)
  fi
fi
