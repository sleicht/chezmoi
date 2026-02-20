---
phase: 32-fzf-enhancement
plan: 01
subsystem: shell/fzf
tags: [fzf, ui, theming, dracula, eza]
dependency_graph:
  requires: [bat, eza, fd]
  provides: [fzf-dracula-theme, fzf-widget-previews]
  affects: [fzf, zsh-completion]
tech_stack:
  added: []
  patterns: [fzf-opts-configuration, widget-preview-commands]
key_files:
  created: []
  modified:
    - dot_zsh.d/external-sync.zsh
    - dot_zshenv
decisions: []
metrics:
  duration_minutes: 1
  tasks_completed: 2
  files_modified: 2
  commits: 2
  completed_date: 2026-02-16
---

# Phase 32 Plan 01: Configure fzf with Dracula Theme and Rich Widget Previews Summary

**One-liner:** fzf configured with Dracula colour scheme, rounded borders, and rich widget previews using bat (files) and eza tree (directories).

## Objective

Configure fzf with Dracula colour scheme and rich widget previews to deliver a visually unified experience with syntax-highlighted file previews (Ctrl+T) and tree directory previews (Alt+C), all using the Dracula palette.

## Tasks Completed

### Task 1: Add Dracula theme and widget preview commands to fzf configuration
**Status:** ✓ Complete
**Commit:** 8b824c4
**Files:** `dot_zsh.d/external-sync.zsh`

Updated `external-sync.zsh` with:
- Dracula colour palette added to `FZF_DEFAULT_OPTS` with all standard Dracula fzf colour values
- `--border=rounded` for rounded corner borders
- `--preview-window=bottom,40%,border-rounded` for preview pane positioning
- `FZF_ALT_C_OPTS` configured to use `eza --tree --level=2 --icons --color=always` for directory previews
- `FZF_CTRL_T_OPTS` kept using `_fzf_complete_realpath` for file previews
- All existing binds, layout settings, and commands preserved unchanged

### Task 2: Update _fzf_complete_realpath to use eza for directory previews
**Status:** ✓ Complete
**Commit:** 2ca7cac
**Files:** `dot_zshenv`

Updated `_fzf_complete_realpath` function:
- Replaced `tree` command with `eza --tree --level=2 --icons --color=always -a --ignore-glob='.DS_Store|.localized'` for directory previews
- Preserved 2-level depth tree display with nerd font icons
- Kept ignore patterns for `.DS_Store` and `.localized` files
- File preview with bat (line numbers, Dracula theme) unchanged
- Binary/image/stdin handling unchanged

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All verification checks passed:
1. ✓ `external-sync.zsh` has no syntax errors
2. ✓ `dot_zshenv` has no syntax errors
3. ✓ `FZF_DEFAULT_OPTS` contains Dracula colour values (`bd93f9`, `282a36`, etc.)
4. ✓ `FZF_DEFAULT_OPTS` contains `--border=rounded` and `--preview-window=bottom,40%,border-rounded`
5. ✓ `FZF_ALT_C_OPTS` uses `eza --tree` for directory previews
6. ✓ `_fzf_complete_realpath` function uses `eza --tree` for directory handling

## Success Criteria Met

- ✓ fzf uses Dracula colour palette with rounded borders
- ✓ Preview pane positioned at bottom, 40% height, with rounded border
- ✓ Ctrl+T shows bat-highlighted file preview via `_fzf_complete_realpath`
- ✓ Alt+C shows eza tree with icons for directory preview
- ✓ `_fzf_complete_realpath` uses eza for directories, bat for files (with line numbers)
- ✓ No shell syntax errors in modified files

## Technical Notes

**Dracula Colour Palette Applied:**
- Foreground: `#f8f8f2`, Background: `#282a36`
- Highlight: `#bd93f9`, Current line: `#44475a`
- Info: `#ffb86c`, Prompt: `#50fa7b`
- Pointer/Marker: `#ff79c6`, Header: `#6272a4`

**Widget Preview Configuration:**
- `FZF_CTRL_T_OPTS`: Uses `_fzf_complete_realpath` which dispatches to bat (files) or eza (directories)
- `FZF_ALT_C_OPTS`: Directly calls `eza --tree --level=2 --icons` since Alt+C only handles directories
- Preview window: bottom 40% with rounded borders for consistent visual experience

**Dependencies:**
- `bat` with Dracula theme for syntax-highlighted file previews
- `eza` for rich directory tree display with nerd font icons
- `fd` for file/directory listing (existing, unchanged)

## Self-Check: PASSED

**Files verified:**
- ✓ `/Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/external-sync.zsh` exists and modified
- ✓ `/Users/stephanlv_fanaka/.local/share/chezmoi/dot_zshenv` exists and modified

**Commits verified:**
- ✓ `8b824c4` - Task 1 commit exists
- ✓ `2ca7cac` - Task 2 commit exists

All claims in this summary have been verified against the actual filesystem and git history.
