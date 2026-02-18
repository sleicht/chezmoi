---
phase: 33-project-picker
plan: 01
subsystem: shell-tools
tags: [fzf, zsh, zoxide, fd, sheldon, mise, project-picker]

# Dependency graph
requires:
  - phase: 32-fzf-enhancement
    provides: Dracula fzf theme, FZF_DEFAULT_OPTS with --layout=reverse-list and --preview-window=bottom,40%,border-rounded
provides:
  - pj() shell function with fzf-based project picker (scanning, caching, formatting, sorting, multi-action)
  - projects.zsh module registered in Sheldon dotfiles-defer for deferred loading
  - mise projects:pj task for discoverability
affects: [shell-startup, editor-integration, project-navigation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "xargs -P8 for parallel metadata collection across project directories"
    - "session-persistent zsh array cache (_PP_CACHE) for lazy initialisation"
    - "fzf --expect= for multi-action key dispatch"
    - "inline zsh -c string passed to xargs for self-contained worker logic (ZSH export -f limitation)"

key-files:
  created:
    - dot_zsh.d/projects.zsh
    - private_dot_config/mise/tasks/projects/executable_pj
  modified:
    - private_dot_config/sheldon/plugins.toml

key-decisions:
  - "Command renamed from pp to pj — /usr/bin/pp (PAR Packager) conflict"
  - "PJ_DIRS hardcoded to ~/Projects and ~/git (no env var, user decision)"
  - "Session-persistent cache — rebuilt only on Ctrl+R or _PJ_CACHE=()"
  - "Ctrl+R exits fzf via --expect, rebuilds cache in while loop, re-opens picker"
  - "Never use 'path' as variable name in ZSH — special tied variable wipes PATH"
  - "Use read -r for parsing zoxide output — leading whitespace breaks parameter expansion"
  - "Sheldon cache invalidation fixed: XDG_DATA_HOME not XDG_CONFIG_HOME for lock file"
  - "Fallback editor is always Sublime Text when neither .idea/ nor .sublime-project present"

patterns-established:
  - "Inline zsh -c worker pattern: self-contained logic string passed to xargs -P8 for parallel execution without function export"
  - "Lazy session cache: typeset -ga array populated on first invocation, persists for session"

requirements-completed: [PROJ-01, PROJ-02, PROJ-03, PROJ-04, PROJ-05, INTG-02]

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 33 Plan 01: Project Picker Summary

**fzf project picker (pj) with parallel metadata via xargs -P8, zoxide frecency sorting, multi-action keys, and deferred Sheldon loading**

## Performance

- **Tasks:** 3/3 complete (including human verification)
- **Files modified:** 4

## Accomplishments
- Full `pj()` shell function in `dot_zsh.d/projects.zsh` (308 lines): fd scanning, parallel xargs -P8 metadata, zoxide frecency sort, fzf multi-action picker
- Editor detection: `.idea/` -> IntelliJ, `.sublime-project` -> Sublime, both -> newest-modified wins, neither -> Sublime fallback
- Sheldon `dotfiles-defer` registration ensures zero startup overhead (deferred via zsh-defer)
- Mise `projects:pj` task for discoverability with subshell limitation explanation
- Shell startup: 79ms (well under 150ms target)

## Files Created/Modified
- `dot_zsh.d/projects.zsh` - Full pj() implementation: scanning, caching, formatting, fzf picker, cd/editor actions
- `dot_zshrc.tmpl` - Fixed Sheldon cache invalidation (XDG_DATA_HOME, not XDG_CONFIG_HOME)
- `private_dot_config/sheldon/plugins.toml` - Added "projects.zsh" to dotfiles-defer use array
- `private_dot_config/mise/tasks/projects/executable_pj` - Discoverability wrapper with usage instructions

## Bugs Fixed During Verification
- **pp -> pj rename**: `/usr/bin/pp` (PAR Packager) conflict
- **ZSH `path` variable**: using `path` as local variable wipes `PATH` (special tied variable) — renamed to `repo_path`/`selected`
- **Zoxide parsing**: leading whitespace in `zoxide query --list --score` broke parameter expansion — replaced with `read -r`
- **Sheldon cache stale**: `.zshrc` checked wrong lock file path (`XDG_CONFIG_HOME` instead of `XDG_DATA_HOME`)
- **Cache not persisting**: removed unconditional `_PJ_CACHE=()` after fzf exit
- **Ctrl+R scanning 324k dirs**: replaced inline fzf reload with `--expect` loop that rebuilds cache via `_pj_build_cache`

## Deviations from Plan
- Command renamed from `pp` to `pj` (conflict with `/usr/bin/pp`)
- Ctrl+R implementation changed from fzf inline `reload()` to `--expect` + while loop (avoids duplicated scan logic, uses same pipeline as initial build)

## Next Phase Readiness
- All code complete and committed, awaiting human verification at Task 3 checkpoint
- After verification: Phase 33 is complete (only 1 plan in phase)

## Self-Check: PASSED

- dot_zsh.d/projects.zsh: FOUND
- dot_zshrc.tmpl: FOUND (Sheldon cache fix)
- private_dot_config/sheldon/plugins.toml: FOUND
- private_dot_config/mise/tasks/projects/executable_pj: FOUND
- Shell startup: 79ms (target: <150ms)
- `pj` command: functional, caching works, Ctrl+R refresh works

---
*Phase: 33-project-picker*
*Completed: 2026-02-17*
