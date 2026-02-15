---
phase: 29-reintegration
plan: 01
subsystem: documentation
tags: [runbook, migration, chezmoi, reintegration]

# Dependency graph
requires:
  - phase: 26-pre-migration-audit
    provides: Migration audit artefacts (untracked scripts, env vars, drift analysis)
  - phase: 28-migration
    provides: Completed dotbot-to-chezmoi migration with local edits preserved
provides:
  - Reintegration runbook with 3 procedures covering script triage, env var reintegration, and config merge workflows
affects: [30-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Three-category triage pattern (add to chezmoi / keep local / discard) for migration artefacts"
    - "Machine-type conditional deployment via .chezmoiignore and template blocks"
    - "Local override file pattern (~/.zsh.d.local) for unmanaged machine-specific configs"

key-files:
  created:
    - .planning/phases/29-reintegration/RUNBOOK-04-reintegration.md
  modified: []

key-decisions:
  - "Script triage uses chezmoi add with .chezmoiignore for machine-type conditionals rather than manual source file creation"
  - "Environment variables reintegrated either via chezmoi templates (stable client-specific values) or local override file (secrets/ephemeral values)"
  - "Config merges support three approaches: manual edit (simple), chezmoi merge (complex), and source overwrite (when local version is definitively better)"
  - "Local-only scripts documented in ~/migration-audit/local-scripts-inventory.txt for future reference"

patterns-established:
  - "Decision framework: for each migration artefact, classify as add to chezmoi / keep local / discard based on scope, stability, and security"
  - "Template conversion workflow: rename source file to .tmpl suffix in chezmoi source, then add Go template conditionals"
  - "Local override sourcing: managed sourcing line in .zshrc, unmanaged override file stays outside chezmoi"

# Metrics
duration: 6min
completed: 2026-02-15
---

# Phase 29 Plan 01: Reintegration Summary

**Step-by-step reintegration runbook for evaluating and merging local customisations from Phase 26 audit back into chezmoi-managed dotfiles**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-15T10:00:00Z
- **Completed:** 2026-02-15T20:46:19Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Created comprehensive reintegration runbook with 3 procedures (REINT-01 through REINT-03)
- Established triage decision framework: add to chezmoi / keep local / discard for all migration artefact types
- Defined machine-type conditional deployment patterns via .chezmoiignore and template blocks
- Provided local override file pattern (~/.zsh.d.local) for unmanaged machine-specific configurations
- User verified runbook accuracy for client Mac setup

## Task Commits

Each task was committed atomically:

1. **Task 1: Create reintegration runbook** - `14a5c90` (docs)
2. **Task 2: Review reintegration runbook for accuracy** - checkpoint:human-verify (user approved)

**Plan metadata:** (to be committed with SUMMARY.md and STATE.md updates)

## Files Created/Modified
- `.planning/phases/29-reintegration/RUNBOOK-04-reintegration.md` - Reintegration procedures for custom scripts, env vars, and config edits

## Decisions Made

**Script Triage Approach:**
- Use `chezmoi add` for scripts to be managed, rather than manually creating source files
- Client-only scripts managed via .chezmoiignore exclusion for non-client machines
- Local-only scripts documented in ~/migration-audit/local-scripts-inventory.txt

**Environment Variable Reintegration:**
- Stable client-specific variables: template in chezmoi via machine_type conditionals
- Secrets/ephemeral values: keep in local override file (~/.zsh.d.local)
- Template conversion: rename .zsh to .zsh.tmpl in chezmoi source, add Go template blocks
- Local override file sourcing: managed source line in .zshrc, unmanaged override file

**Config Merge Workflows:**
- Three approaches provided based on change complexity:
  - Manual edit: simple changes via `chezmoi edit`
  - chezmoi merge: complex changes with three-way merge (if configured)
  - Source overwrite: when local version is definitively better
- Drift diff review references both Phase 28 local-edits/ and Phase 26 drift-triage.md

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Reintegration runbook complete and user-approved. Ready for Phase 30 (Verification) planning. User will follow this runbook on the client Mac after completing Phase 28 migration to merge local customisations back into chezmoi source.

**Runbook structure:**
- Purpose, Prerequisites, Output headers
- Procedure 1: Evaluate Custom Scripts (REINT-01) - script triage workflow
- Procedure 2: Reintegrate Environment Variables (REINT-02) - env var classification and integration
- Procedure 3: Merge Drifted Config Edits (REINT-03) - local edits merge workflow
- Summary, Verification command, Next Steps

**Decision frameworks:**
- Scripts: add to chezmoi (useful across machines) / keep local (machine-specific) / discard (obsolete)
- Env vars: already handled / add to template / add to local override / no longer needed
- Config edits: valuable (merge) / stale (discard) / machine-specific (template or local override)

---
*Phase: 29-reintegration*
*Completed: 2026-02-15*
