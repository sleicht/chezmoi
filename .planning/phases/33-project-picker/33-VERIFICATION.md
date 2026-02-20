---
phase: 33-project-picker
verified: 2026-02-20T00:00:00Z
status: passed
score: 9/9 must-haves verified
re_verification: false
human_verification:
  - test: "Run pj and verify display format, preview pane, cd behaviour, Ctrl+E/Ctrl+O/Ctrl+R, Escape, and mise tasks listing"
    expected: "All keybindings work, startup 79ms, caching works"
    why_human: "Interactive fzf picker, cd side-effect, editor launch, startup timing"
    result: "PASSED — confirmed by human verification on 2026-02-18"
---

# Phase 33: Project Picker Verification Report

**Phase Goal:** Users can rapidly discover and navigate to projects with optional editor integration
**Verified:** 2026-02-20
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                     | Status     | Evidence                                                                                             |
|----|---------------------------------------------------------------------------|------------|------------------------------------------------------------------------------------------------------|
| 1  | User can invoke project picker via `pj` shell command                     | VERIFIED   | `pj()` defined at line 287 of `dot_zsh.d/projects.zsh`; explicit design decision: no ZSH key binding per CONTEXT.md |
| 2  | Project list shows parent/name, branch*, path, relative time, editor icon | VERIFIED   | `printf "%-35s  %-22s  %-45s  %-8s  %s"` with all five fields at lines 182-184                     |
| 3  | Projects sorted by zoxide frecency first, mtime fallback                  | VERIFIED   | `_pj_build_cache()` two-pass: zoxide-ordered entries first (lines 232-238), remaining sorted by mtime (lines 241-258) |
| 4  | User can cd to selected project in current shell                          | VERIFIED   | `cd "$selected"` in default case of `pj()` at line 332; shell function (not subshell) preserves effect |
| 5  | User can press Ctrl+E to open detected editor without changing directory  | VERIFIED   | `ctrl-e` case calls `_pj_open_editor "$selected"` at line 326                                       |
| 6  | User can press Ctrl+O to cd and open editor                               | VERIFIED   | `ctrl-o` case calls `cd "$selected" && _pj_open_editor "$selected"` at line 329                     |
| 7  | User can press Ctrl+R inside picker to refresh the project list           | VERIFIED   | `--expect=ctrl-e,ctrl-o,ctrl-r`; while-loop detects `ctrl-r`, clears `_PJ_CACHE` and calls `_pj_build_cache` (lines 308-312) |
| 8  | Preview pane shows git log --oneline --graph for selected project         | VERIFIED   | `--preview='git -C {-1} log --oneline --graph --color=always -15 2>/dev/null'` at line 299           |
| 9  | Shell startup time remains under 150ms                                    | VERIFIED   | Human-verified at 79ms; module registered in `dotfiles-defer` (deferred via `zsh-defer`), no computation at source time |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact                                                         | Expected                                                               | Status    | Details                                                                          |
|------------------------------------------------------------------|------------------------------------------------------------------------|-----------|----------------------------------------------------------------------------------|
| `dot_zsh.d/projects.zsh`                                         | pj() function with scanning, caching, formatting, sorting, fzf picker | VERIFIED  | 335 lines (exceeds min_lines: 100); all required functions present; syntax valid |
| `private_dot_config/sheldon/plugins.toml`                        | projects.zsh registered in dotfiles-defer use array                   | VERIFIED  | Line 70: `"projects.zsh"` present in dotfiles-defer use array                   |
| `private_dot_config/mise/tasks/projects/executable_pj`           | Discoverability wrapper with usage instructions                        | VERIFIED  | 12 lines with MISE description header and key usage; renamed from executable_pp per plan deviation |

**Note on PLAN frontmatter deviation:** The PLAN's `artifacts` section listed `executable_pp` (the original command name) and `_PP_CACHE`. The implementation uses `executable_pj` and `_PJ_CACHE` throughout, reflecting the documented `pp -> pj` rename. All functionality is present and correct.

### Key Link Verification

| From                                     | To      | Via                                                | Status  | Details                                                                                  |
|------------------------------------------|---------|----------------------------------------------------|---------|------------------------------------------------------------------------------------------|
| `dot_zsh.d/projects.zsh`                 | `fd`    | fd scanning for `^.git$` directories              | WIRED   | Line 98: `"^\.git$" "${PJ_DIRS[@]}"` in `_pj_scan()` with `--hidden --no-ignore --type d` |
| `dot_zsh.d/projects.zsh`                 | `zoxide`| `zoxide query --list --score` for frecency sorting | WIRED   | Line 216: `done < <(zoxide query --list --score 2>/dev/null)`                            |
| `dot_zsh.d/projects.zsh`                 | `fzf`   | `--expect=ctrl-e,ctrl-o,ctrl-r` multi-action picker | WIRED  | Line 295: `--expect=ctrl-e,ctrl-o,ctrl-r` (superset of planned `ctrl-e,ctrl-o`; ctrl-r added per documented deviation) |
| `private_dot_config/sheldon/plugins.toml`| `dot_zsh.d/projects.zsh` | dotfiles-defer use array includes projects.zsh | WIRED | Line 70 of plugins.toml: `"projects.zsh"` in `[plugins.dotfiles-defer]` use array |

### Requirements Coverage

| Requirement | Description                                                                | Status    | Evidence                                                                             |
|-------------|----------------------------------------------------------------------------|-----------|--------------------------------------------------------------------------------------|
| PROJ-01     | User can invoke fzf-based project picker via key binding or command        | SATISFIED | `pj()` shell function; no ZSH key binding (explicit decision: command-only)         |
| PROJ-02     | Project picker scans configurable list of parent directories for git repos | SATISFIED | `PJ_DIRS` array (default `~/Projects ~/git`); `_pj_scan()` uses fd with `PJ_DIRS[@]` |
| PROJ-03     | User can cd to selected project                                            | SATISFIED | `cd "$selected"` in `pj()` default/Enter case                                       |
| PROJ-04     | User can optionally open selected project in IntelliJ IDEA or Sublime Text | SATISFIED | `_pj_open_editor()` with `.idea/` -> IntelliJ, `.sublime-project` -> Sublime; Ctrl+E/Ctrl+O dispatch |
| PROJ-05     | Project list shows useful context (branch, last modified, path)            | SATISFIED | Display format: parent/name, branch (with dirty `*`), tilde-path, relative time, editor label |
| INTG-02     | All new configuration respects sync/defer architecture (no startup regression) | SATISFIED | Registered in `dotfiles-defer` (deferred via `zsh-defer`); no computation at source time; startup verified at 79ms |

### Anti-Patterns Found

None. No TODO/FIXME/placeholder comments, no empty implementations, no stub return values found in `dot_zsh.d/projects.zsh` or `private_dot_config/mise/tasks/projects/executable_pj`.

### Human Verification

Human verification was completed on 2026-02-18 (documented in SUMMARY.md). Results:

1. **Shell startup timing**
   - Test: `time zsh -i -c exit`
   - Expected: under 150ms
   - Result: 79ms — PASSED

2. **Project picker invocation and display**
   - Test: run `pj`, observe fzf picker
   - Expected: shows projects from ~/Projects and ~/git with formatted lines
   - Result: PASSED

3. **Keybindings (Enter, Ctrl+E, Ctrl+O, Ctrl+R, Escape)**
   - Test: exercise each key in the picker
   - Result: all keybindings work — PASSED

4. **Caching behaviour**
   - Test: invoke `pj` a second time; should be instant
   - Result: caching works — PASSED

5. **Mise discoverability**
   - Test: `mise tasks` — should show `projects:pj`
   - Result: PASSED

### Implementation Notes

**Documented deviations from PLAN (all intentional, recorded in SUMMARY key-decisions):**

1. Command renamed `pp` -> `pj`: `/usr/bin/pp` (PAR Packager) conflict. All variables, functions, and file names updated consistently (`_PJ_CACHE`, `_pj_*` helpers, `executable_pj`, `PJ_DIRS`, etc.).

2. Ctrl+R via `--expect` loop instead of fzf inline `reload()`: avoids duplicated scan logic and uses the same `_pj_build_cache` pipeline as the initial build. The while-loop in `pj()` detects `ctrl-r`, rebuilds cache, and re-opens the picker.

3. Disk cache added (not in PLAN): `PJ_CACHE_FILE` and `PJ_CACHE_TTL` (1h default) persist the in-memory cache to `~/.cache/pj/cache`. This is an enhancement beyond the session-only cache in the PLAN — `_pj_load_cache()` checks disk cache TTL before rebuilding. This does not break any success criterion.

4. `--expect` pattern extended: PLAN specified `ctrl-e,ctrl-o`; implementation uses `ctrl-e,ctrl-o,ctrl-r` to integrate Ctrl+R into the same expect mechanism.

---

_Verified: 2026-02-20_
_Verifier: Claude (gsd-verifier)_
