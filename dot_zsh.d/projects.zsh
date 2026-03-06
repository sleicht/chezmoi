# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# `projects.zsh` — thin wrapper around the pj-picker Go binary.
# The binary handles scanning, caching, zoxide ordering, and fzf.
# This wrapper handles cd and editor launch (which require the parent shell).

_pj_open_editor() {
  local repo=$1
  local has_idea has_sublime
  [[ -d "$repo/.idea" ]] && has_idea=1
  fd -e sublime-project --max-depth 1 . "$repo" --quiet 2>/dev/null && has_sublime=1

  if [[ -n "$has_idea" && -n "$has_sublime" ]]; then
    local idea_mtime sublime_mtime sublime_file
    idea_mtime=$(stat -f '%m' "$repo/.idea" 2>/dev/null || echo 0)
    sublime_file=$(fd -e sublime-project --max-depth 1 . "$repo" 2>/dev/null | head -1)
    sublime_mtime=$(stat -f '%m' "$sublime_file" 2>/dev/null || echo 0)
    if (( idea_mtime >= sublime_mtime )); then
      idea "$repo" &>/dev/null & disown
    else
      subl "$repo" &>/dev/null & disown
    fi
  elif [[ -n "$has_idea" ]]; then
    idea "$repo" &>/dev/null & disown
  else
    subl "$repo" &>/dev/null & disown
  fi
}

pj() {
  local output
  output=$(pj-picker) || return 0

  [[ -z "$output" ]] && return 0

  local action="${output%%	*}"
  local target="${output#*	}"

  case "$action" in
    cd)
      cd "$target"
      ;;
    editor)
      _pj_open_editor "$target"
      ;;
    cd+editor)
      cd "$target" && _pj_open_editor "$target"
      ;;
  esac
}
