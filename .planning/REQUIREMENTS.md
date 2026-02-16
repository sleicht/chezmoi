# Requirements: Dotfiles Stack

**Defined:** 2026-02-16
**Core Value:** Cross-platform dotfiles that "just work" -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.

## v4.0 Requirements

Requirements for v4.0 Shell UX Polish. Wire existing shell tools together for a polished UX.

### fzf-tab Configuration

- [ ] **FZFT-01**: fzf-tab shows bat-highlighted file preview when completing file paths
- [ ] **FZFT-02**: fzf-tab shows eza/tree directory preview when completing directories
- [ ] **FZFT-03**: fzf-tab shows process info preview when completing PIDs (kill)
- [ ] **FZFT-04**: fzf-tab shows environment variable values when completing env vars
- [ ] **FZFT-05**: fzf-tab shows git diff preview when completing branch names
- [ ] **FZFT-06**: fzf-tab shows git log preview when completing commit hashes

### fzf Widget Previews

- [ ] **FZFW-01**: Ctrl+T file picker shows bat syntax-highlighted file content in preview pane
- [ ] **FZFW-02**: Alt+C directory picker shows eza tree view in preview pane

### Project Picker

- [ ] **PROJ-01**: User can invoke fzf-based project picker via key binding or command
- [ ] **PROJ-02**: Project picker scans configurable list of parent directories for git repos
- [ ] **PROJ-03**: User can cd to selected project
- [ ] **PROJ-04**: User can optionally open selected project in IntelliJ IDEA or Sublime Text
- [ ] **PROJ-05**: Project list shows useful context (branch, last modified, path)

### Integration

- [ ] **INTG-01**: Carapace completions render correctly in fzf-tab menus
- [ ] **INTG-02**: All new configuration respects sync/defer architecture (no startup regression)

## Future Requirements

None deferred.

## Out of Scope

| Feature | Reason |
|---------|--------|
| tmux/zellij session management | User uses terminal tabs, not multiplexer sessions |
| vi-mode key bindings | User has mixed/custom emacs-based setup, no changes needed |
| New CLI tool installations | Milestone is about wiring existing tools, not adding new ones |
| Atuin history configuration | Already working well, not part of this milestone |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FZFT-01 | — | Pending |
| FZFT-02 | — | Pending |
| FZFT-03 | — | Pending |
| FZFT-04 | — | Pending |
| FZFT-05 | — | Pending |
| FZFT-06 | — | Pending |
| FZFW-01 | — | Pending |
| FZFW-02 | — | Pending |
| PROJ-01 | — | Pending |
| PROJ-02 | — | Pending |
| PROJ-03 | — | Pending |
| PROJ-04 | — | Pending |
| PROJ-05 | — | Pending |
| INTG-01 | — | Pending |
| INTG-02 | — | Pending |

**Coverage:**
- v4.0 requirements: 15 total
- Mapped to phases: 0
- Unmapped: 15

---
*Requirements defined: 2026-02-16*
*Last updated: 2026-02-16 after initial definition*
