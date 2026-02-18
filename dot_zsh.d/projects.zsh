# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zsh.d/
#!/usr/bin/env zsh

# `projects.zsh` provides the `pj` interactive project picker.


# === Configuration ===

PJ_DIRS=("$HOME/Projects" "$HOME/git")
PJ_DEPTH=${PJ_DEPTH:-2}
PJ_EXCLUDES=(node_modules .cache vendor target build dist __pycache__)

# Session-persistent cache (populated lazily on first `pj` invocation)
typeset -ga _PJ_CACHE


# === Helpers ===

_pj_relative_time() {
  local ts=$1
  local now delta
  now=$(date +%s)
  (( delta = now - ts ))
  if (( delta < 3600 )); then
    echo "$(( delta / 60 ))m ago"
  elif (( delta < 86400 )); then
    echo "$(( delta / 3600 ))h ago"
  elif (( delta < 604800 )); then
    echo "$(( delta / 86400 ))d ago"
  else
    echo "$(( delta / 604800 ))w ago"
  fi
}

_pj_detect_editor() {
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
      echo "[IJ]"
    else
      echo "[SL]"
    fi
  elif [[ -n "$has_idea" ]]; then
    echo "[IJ]"
  elif [[ -n "$has_sublime" ]]; then
    echo "[SL]"
  fi
}

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


# === Scan & format ===

_pj_scan() {
  local -a exclude_args=()
  for ex in "${PJ_EXCLUDES[@]}"; do
    exclude_args+=(-E "$ex")
  done

  # Find git repos
  local git_repos
  git_repos=$(fd --hidden --no-ignore --type d \
    --max-depth "$(( PJ_DEPTH * 2 ))" \
    "${exclude_args[@]}" \
    "^\.git$" "${PJ_DIRS[@]}" 2>/dev/null | sed 's|/\.git/?$||')

  # Find non-git project marker directories
  local marker_repos
  marker_repos=$(fd --hidden --no-ignore \
    --max-depth "$(( PJ_DEPTH * 2 ))" \
    "${exclude_args[@]}" \
    "(^package\.json$|^go\.mod$|^Cargo\.toml$|^pom\.xml$|^Makefile$|^build\.gradle$|^pyproject\.toml$)" \
    "${PJ_DIRS[@]}" 2>/dev/null | xargs -I{} dirname {} 2>/dev/null | sort -u)

  # Merge: exclude marker dirs that already have .git
  local all_repos
  all_repos=$(
    echo "$git_repos"
    while IFS= read -r dir; do
      [[ -n "$dir" && ! -d "$dir/.git" ]] && echo "$dir"
    done <<< "$marker_repos"
  )

  # Parallel metadata collection via xargs -P8
  # The inline zsh script is self-contained (no external function refs)
  echo "$all_repos" | grep -v '^$' | xargs -I{} -P8 zsh -c '
    repo="$1"
    [[ -z "$repo" ]] && exit 0

    # parent/name
    home_stripped="${repo#$HOME/}"
    parent=$(dirname "$home_stripped")
    name=$(basename "$home_stripped")
    if [[ "$parent" == "." ]]; then
      proj_label="$name"
    else
      proj_label="$parent/$name"
    fi

    # branch + dirty indicator
    branch=$(git -C "$repo" branch --show-current 2>/dev/null)
    [[ -z "$branch" ]] && branch="(detached)"
    dirty=$(git -C "$repo" status --porcelain -uno 2>/dev/null | head -1)
    [[ -n "$dirty" ]] && branch="${branch}*"

    # tilde path
    tilde_path="~/${repo#$HOME/}"

    # relative time from mtime
    mtime=$(stat -f "%m" "$repo" 2>/dev/null || echo 0)
    now=$(date +%s)
    delta=$(( now - mtime ))
    if (( delta < 3600 )); then
      rel_time="$(( delta / 60 ))m ago"
    elif (( delta < 86400 )); then
      rel_time="$(( delta / 3600 ))h ago"
    elif (( delta < 604800 )); then
      rel_time="$(( delta / 86400 ))d ago"
    else
      rel_time="$(( delta / 604800 ))w ago"
    fi

    # editor detection
    has_idea=0
    has_sublime=0
    [[ -d "$repo/.idea" ]] && has_idea=1
    fd -e sublime-project --max-depth 1 . "$repo" --quiet 2>/dev/null && has_sublime=1

    if (( has_idea && has_sublime )); then
      idea_mtime=$(stat -f "%m" "$repo/.idea" 2>/dev/null || echo 0)
      sublime_file=$(fd -e sublime-project --max-depth 1 . "$repo" 2>/dev/null | head -1)
      sublime_mtime=$(stat -f "%m" "$sublime_file" 2>/dev/null || echo 0)
      if (( idea_mtime >= sublime_mtime )); then
        editor_label="[IJ]"
      else
        editor_label="[SL]"
      fi
    elif (( has_idea )); then
      editor_label="[IJ]"
    elif (( has_sublime )); then
      editor_label="[SL]"
    else
      editor_label=""
    fi

    display=$(printf "%-35s  %-22s  %-45s  %-8s  %s" \
      "$proj_label" "$branch" "$tilde_path" "$rel_time" "$editor_label")
    printf "%s|%s\n" "$display" "$repo"
  ' -- {}
}


# === Cache ===

_pj_build_cache() {
  _PJ_CACHE=()

  # Step 1: zoxide-tracked repos filtered to PJ_DIRS
  local -a zoxide_paths=()
  local -a zoxide_ordered=()
  while IFS= read -r line; do
    local score repo_path
    read -r score repo_path <<< "$line"
    # Check if repo_path is under a PJ_DIR and has .git or project marker
    local in_scope=0
    for ppdir in "${PJ_DIRS[@]}"; do
      [[ "$repo_path" == "$ppdir"/* ]] && in_scope=1 && break
    done
    (( in_scope )) || continue
    if [[ -d "$repo_path/.git" ]] || \
       [[ -f "$repo_path/package.json" ]] || \
       [[ -f "$repo_path/go.mod" ]] || \
       [[ -f "$repo_path/Cargo.toml" ]] || \
       [[ -f "$repo_path/pom.xml" ]] || \
       [[ -f "$repo_path/Makefile" ]] || \
       [[ -f "$repo_path/build.gradle" ]] || \
       [[ -f "$repo_path/pyproject.toml" ]]; then
      zoxide_paths+=("$repo_path")
    fi
  done < <(zoxide query --list --score 2>/dev/null)

  # Step 2: full scan for formatted display lines
  local -a all_lines=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && all_lines+=("$line")
  done < <(_pj_scan)

  # Step 3: build lookup map from path -> display line
  local -A path_to_line=()
  for entry in "${all_lines[@]}"; do
    local epath="${entry##*|}"
    path_to_line[$epath]="$entry"
  done

  # Step 4: zoxide-ordered first
  local -A seen=()
  for zpath in "${zoxide_paths[@]}"; do
    if [[ -n "${path_to_line[$zpath]}" && -z "${seen[$zpath]}" ]]; then
      _PJ_CACHE+=("${path_to_line[$zpath]}")
      seen[$zpath]=1
    fi
  done

  # Step 5: remaining repos sorted by mtime (newest first)
  local -a remaining=()
  for entry in "${all_lines[@]}"; do
    local epath="${entry##*|}"
    if [[ -z "${seen[$epath]}" ]]; then
      local mtime
      mtime=$(stat -f '%m' "$epath" 2>/dev/null || echo 0)
      remaining+=("${mtime}|${entry}")
    fi
  done

  # Sort remaining by mtime descending
  local -a sorted_remaining=()
  while IFS= read -r line; do
    sorted_remaining+=("${line#*|}")
  done < <(printf '%s\n' "${remaining[@]}" | sort -t'|' -k1 -rn)

  for entry in "${sorted_remaining[@]}"; do
    _PJ_CACHE+=("$entry")
  done
}


# === Main picker ===

pj() {
  # Lazy cache build
  [[ ${#_PJ_CACHE[@]} -eq 0 ]] && _pj_build_cache

  local result key selected

  while true; do
    result=$(printf '%s\n' "${_PJ_CACHE[@]}" | fzf \
      --expect=ctrl-e,ctrl-o,ctrl-r \
      --ansi \
      --delimiter='|' \
      --with-nth=1 \
      --preview='git -C {-1} log --oneline --graph --color=always -15 2>/dev/null' \
      --preview-window=bottom,40%,border-rounded \
      --header='Enter: cd  |  Ctrl+E: editor  |  Ctrl+O: cd+editor  |  Ctrl+R: refresh' \
      --layout=reverse-list \
      2>/dev/null)

    key=$(head -1 <<< "$result")

    # Ctrl+R: rebuild cache and re-open picker
    if [[ "$key" == "ctrl-r" ]]; then
      _PJ_CACHE=()
      _pj_build_cache
      continue
    fi

    break
  done

  [[ -z "$result" ]] && return 0

  selected=$(tail -1 <<< "$result")
  selected="${selected##*|}"

  [[ -z "$selected" ]] && return 0

  case "$key" in
    ctrl-e)
      _pj_open_editor "$selected"
      ;;
    ctrl-o)
      cd "$selected" && _pj_open_editor "$selected"
      ;;
    *)
      cd "$selected"
      ;;
  esac
}
