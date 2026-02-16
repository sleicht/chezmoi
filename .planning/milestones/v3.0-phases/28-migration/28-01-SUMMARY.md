---
phase: 28-migration
plan: 01
subsystem: infra
tags: [chezmoi, dotbot, migration, runbook, documentation]

# Dependency graph
requires:
  - phase: 26-pre-migration-audit
    provides: "Local state capture in ~/migration-audit/ (dotbot-symlinks.txt, dotfiles drift)"
  - phase: 27-bootstrap
    provides: "Chezmoi infrastructure (age key, repo clone, chezmoi init)"
provides:
  - "Migration runbook with 3 procedures for safe Dotbot-to-chezmoi transition"
  - "Symlink materialisation strategy with backup"
  - "Conflict resolution workflow with local edit preservation"
affects: [29-reintegration, 31-cleanup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Runbook-based migration approach (human-readable procedures, not automation)"
    - "Symlink materialisation pattern (convert symlinks to real files with backup before chezmoi apply)"
    - "Conflict categorisation (safe to overwrite, merge needed, keep local)"

key-files:
  created:
    - ".planning/phases/28-migration/RUNBOOK-03-migration.md"
  modified: []

key-decisions:
  - "Symlink materialisation approach: cp -L (follow symlink) with backup before rm to safely convert symlinks to real files"
  - "Apply strategy: dry-run first, then verbose apply with full logging to ~/migration-audit/"
  - "Conflict resolution: save valuable local edits to ~/migration-audit/local-edits/, let chezmoi overwrite, merge later in Phase 29"
  - "SSH key deployment: switch chezmoi remote from HTTPS to SSH after SSH keys deployed via chezmoi apply"

patterns-established:
  - "Three-procedure migration pattern: materialise → apply → resolve conflicts"
  - "Audit-driven approach: reference Phase 26 artefacts (dotbot-symlinks.txt, drift diff) throughout procedures"
  - "Safety-net strategy: preserve old dotfiles-zsh repo until Phase 31 rollback window expires"

# Metrics
duration: 35min
completed: 2026-02-15
---

# Phase 28 Plan 01: Migration Summary

**Step-by-step migration runbook for converting Dotbot symlinks to chezmoi-managed files with backup, conflict resolution, and SSH remote setup**

## Performance

- **Duration:** 35 min
- **Started:** 2026-02-15T18:49:00Z
- **Completed:** 2026-02-15T19:24:53Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Migration runbook created with 3 comprehensive procedures covering all MIG requirements
- Procedure 1: Symlink materialisation with backup strategy and verification commands
- Procedure 2: Chezmoi apply workflow with dry-run, template verification, and SSH remote switch
- Procedure 3: Conflict resolution categorisation and local edit preservation for Phase 29
- User reviewed and approved runbook for accuracy against client Mac setup

## Task Commits

Each task was committed atomically:

1. **Task 1: Create migration runbook** - `8b972f0` (docs)
2. **Task 2: Review migration runbook for accuracy** - *(checkpoint:human-verify - user approved, no code changes)*

**Plan metadata:** *(pending - will be added with this summary)*

## Files Created/Modified
- `.planning/phases/28-migration/RUNBOOK-03-migration.md` - Step-by-step migration guide with 3 procedures: materialise Dotbot symlinks (MIG-01), run chezmoi apply (MIG-02), handle conflicts (MIG-03)

## Decisions Made

**Symlink materialisation approach:**
- Use `cp -L` to follow symlinks and copy content to regular files
- Create backup in `~/migration-audit/pre-migration-backup/` before removal
- Verify with spot-checks comparing materialised files against backups

**Chezmoi apply strategy:**
- Dry-run first (`--dry-run --verbose`) to preview changes and catch errors
- Full apply with verbose logging to `~/migration-audit/chezmoi-apply.txt`
- Template verification checks for machine_type and client-specific rendering
- Switch repo remote from HTTPS to SSH after SSH keys deployed

**Conflict resolution workflow:**
- Categorise conflicts: safe to overwrite, merge needed, keep local
- Save valuable local edits to `~/migration-audit/local-edits/` for Phase 29 reintegration
- Use `chezmoi apply --force` for known-safe overwrites
- Verify final state with `chezmoi diff --exclude=scripts` (should be empty)

**Safety strategy:**
- Preserve old `dotfiles-zsh` repo until Phase 31 (rollback safety net)
- Keep `~/migration-audit/` directory for Phase 29 (contains local-edits/ for reintegration)
- Full logging of apply process for troubleshooting reference

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

The runbook provides step-by-step procedures for the user to execute on the client Mac. All commands are documented with expected outputs and troubleshooting guidance.

## Next Phase Readiness

**Ready for Phase 29 (Reintegration):**
- Migration runbook approved and ready for client Mac execution
- Procedures reference Phase 26 audit artefacts (dotbot-symlinks.txt, drift diff)
- Local edit preservation strategy documented for Phase 29 reintegration
- Verification commands provided to confirm migration success

**User next steps:**
1. Execute RUNBOOK-03-migration.md procedures on client Mac
2. Follow Procedure 1 (materialise symlinks) → Procedure 2 (chezmoi apply) → Procedure 3 (resolve conflicts)
3. Verify migration success with final verification command
4. Proceed to Phase 29 for reintegration of custom scripts and local edits

**No blockers.**

## Self-Check: PASSED

**Files verified:**
- FOUND: .planning/phases/28-migration/RUNBOOK-03-migration.md

**Commits verified:**
- FOUND: 8b972f0

All claimed files and commits exist.

---
*Phase: 28-migration*
*Completed: 2026-02-15*
