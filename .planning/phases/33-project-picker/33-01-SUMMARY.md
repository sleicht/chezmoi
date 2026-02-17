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
  - pp() shell function with fzf-based project picker (scanning, caching, formatting, sorting, multi-action)
  - projects.zsh module registered in Sheldon dotfiles-defer for deferred loading
  - mise projects:pp task for discoverability
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
    - private_dot_config/mise/tasks/projects/executable_pp
  modified:
    - private_dot_config/sheldon/plugins.toml

key-decisions:
  - "PP_DIRS hardcoded to ~/Projects and ~/git (no env var, user decision)"
  - "Cache cleared after every fzf session exit so Ctrl+R effects persist to next pp call"
  - "Ctrl+R in fzf uses inline reload command; cache invalidated externally after exit"
  - "Editor detection in _pp_open_editor duplicates _pp_detect_editor logic (ZSH export -f not supported)"
  - "Fallback editor is always Sublime Text when neither .idea/ nor .sublime-project present"

patterns-established:
  - "Inline zsh -c worker pattern: self-contained logic string passed to xargs -P8 for parallel execution without function export"
  - "Lazy session cache: typeset -ga array populated on first invocation, cleared on exit"

requirements-completed: [PROJ-01, PROJ-02, PROJ-03, PROJ-04, PROJ-05, INTG-02]

# Metrics
duration: 2min
completed: 2026-02-17
---

# Phase 33 Plan 01: Project Picker Summary

**fzf project picker (pp) with parallel metadata via xargs -P8, zoxide frecency sorting, multi-action keys, and deferred Sheldon loading**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-17T06:55:22Z
- **Completed:** 2026-02-17T06:57:38Z
- **Tasks:** 2/2 auto tasks complete (1 checkpoint awaiting user verification)
- **Files modified:** 3

## Accomplishments
- Full `pp()` shell function in `dot_zsh.d/projects.zsh` (334 lines): fd scanning, parallel xargs -P8 metadata, zoxide frecency sort, fzf multi-action picker
- Editor detection: `.idea/` -> IntelliJ, `.sublime-project` -> Sublime, both -> newest-modified wins, neither -> Sublime fallback
- Sheldon `dotfiles-defer` registration ensures zero startup overhead (deferred via zsh-defer)
- Mise `projects:pp` task for discoverability with subshell limitation explanation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create projects.zsh module with pp() function** - `ee3e0d2` (feat)
2. **Task 2: Register in Sheldon and create mise task** - `fc92904` (feat)

## Files Created/Modified
- `dot_zsh.d/projects.zsh` - Full pp() implementation: scanning, caching, formatting, fzf picker, cd/editor actions
- `private_dot_config/sheldon/plugins.toml` - Added "projects.zsh" to dotfiles-defer use array
- `private_dot_config/mise/tasks/projects/executable_pp` - Discoverability wrapper with usage instructions

## Decisions Made
- PP_DIRS hardcoded to `~/Projects` and `~/git` (no configurable env var — user decision during planning)
- Cache cleared unconditionally after each fzf session exit (ensures Ctrl+R refresh propagates to next `pp` call without complex subshell signalling)
- Worker logic duplicated inline for xargs -P8 (ZSH does not support `export -f`; shell functions cannot be exported to subprocesses)
- Fallback editor always Sublime Text (user decision: no label shown in list if neither IDE detected, but launch falls back to `subl`)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

`chezmoi apply --dry-run` requires Bitwarden master password — expected authentication gate, not blocking. Verification of deployment will occur at Task 3 checkpoint after user runs `chezmoi apply` + `exec zsh -l`.

## User Setup Required

None - no external service configuration required. User verification at Task 3 checkpoint:
1. `chezmoi apply`
2. `exec zsh -l`
3. `pp` to test picker
4. Verify startup time under 150ms

## Next Phase Readiness
- All code complete and committed, awaiting human verification at Task 3 checkpoint
- After verification: Phase 33 is complete (only 1 plan in phase)

## Self-Check: PASSED

- dot_zsh.d/projects.zsh: FOUND (confirmed via ls)
- private_dot_config/sheldon/plugins.toml: FOUND (confirmed via git status + content grep)
- private_dot_config/mise/tasks/projects/executable_pp: FOUND (confirmed via ls)
- .planning/phases/33-project-picker/33-01-SUMMARY.md: FOUND (this file)
- Commit ee3e0d2: FOUND (confirmed via git log)
- Commit fc92904: FOUND (confirmed via git log)

---
*Phase: 33-project-picker*
*Completed: 2026-02-17*
