---
phase: 27-bootstrap
plan: 01
subsystem: documentation
tags: [runbook, bootstrap, age, chezmoi, migration]

# Dependency graph
requires:
  - phase: 26-pre-migration-audit
    provides: "Audit runbook capturing client Mac state before migration"
provides:
  - "Bootstrap runbook with 3 procedures for setting up chezmoi infrastructure on client Mac"
  - "Age encryption setup with Bitwarden integration"
  - "Chezmoi repository cloning and initialisation guide"
affects: [28-migration, documentation, client-setup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Human-readable runbook format (not automation scripts)"
    - "Procedure structure: Objective → Steps → Expected Output → Troubleshooting → Output"

key-files:
  created:
    - .planning/phases/27-bootstrap/RUNBOOK-02-bootstrap.md
  modified: []

key-decisions:
  - "Runbook uses HTTPS clone initially due to SSH chicken-and-egg (keys encrypted in repo)"
  - "Age private key retrieved from Bitwarden 'dotfiles/shared' folder (cross-machine access)"
  - "Verification uses chezmoi diff instead of chezmoi cat (client SSH configs don't exist yet)"

patterns-established:
  - "Bootstrap procedures follow same format as Phase 26 audit runbook"
  - "Each procedure maps to one BOOT requirement (BOOT-01, BOOT-02, BOOT-03)"

# Metrics
duration: 33min
completed: 2026-02-15
---

# Phase 27 Plan 01: Bootstrap Summary

**Step-by-step bootstrap runbook for setting up age encryption, cloning chezmoi source, and initialising client Mac configuration**

## Performance

- **Duration:** 33 min
- **Started:** 2026-02-15 (first commit e3bcc17)
- **Completed:** 2026-02-15
- **Tasks:** 2 (1 auto + 1 checkpoint)
- **Files created:** 1

## Accomplishments
- Created comprehensive bootstrap runbook with 3 procedures covering all BOOT requirements
- Documented age encryption bootstrap chain (Bitwarden → age key → SSH decryption)
- Provided HTTPS clone workaround for SSH chicken-and-egg problem
- Included verification commands and troubleshooting sections for each procedure

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bootstrap runbook** - `e3bcc17` (docs)
2. **Task 2: Review bootstrap runbook for accuracy** - checkpoint with user approval

**Follow-up refinements based on user review:**
- `e4169ea` - Updated Bitwarden item name to 'age-private-key' in 'dotfiles/shared' folder
- `b061cf7` - Reordered steps to create age key directory first (avoids temp file)
- `e56d23b` - Replaced placeholder repo URLs with actual github.com/sleicht/chezmoi
- `13384de` - Replaced chezmoi cat with chezmoi diff for decryption test (client SSH configs don't exist yet)

## Files Created/Modified
- `.planning/phases/27-bootstrap/RUNBOOK-02-bootstrap.md` - Bootstrap runbook with 3 procedures for client Mac setup

## Decisions Made

1. **HTTPS clone for initial repository setup**: SSH keys are encrypted in the repo (chicken-and-egg), so runbook instructs HTTPS clone initially, then switching to SSH after Phase 28 deploys keys.

2. **Age key in Bitwarden shared folder**: Private key stored in Bitwarden 'dotfiles/shared' folder (item: 'age-private-key') for cross-machine access, not in 'dotfiles/personal' folder.

3. **Verification via chezmoi diff**: Changed from `chezmoi cat ~/.ssh/config` to `chezmoi diff` because client SSH configs don't exist yet on fresh client Mac - diff command still validates age decryption without assuming deployed files.

4. **Directory creation before key write**: Reordered steps to create `~/.config/age/` directory first, then write key directly to final path - avoids temporary files that need cleanup.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed as written. Four follow-up commits made after checkpoint based on user feedback during manual review (correcting Bitwarden paths, repo URLs, and verification commands).

---

**Total deviations:** 0 during execution (4 refinements post-checkpoint)
**Impact on plan:** User review checkpoint identified accuracy issues that were corrected before plan completion.

## Issues Encountered

None during runbook creation. User review process caught issues:
- Incorrect Bitwarden item name and folder path
- Placeholder repo URLs instead of actual github.com/sleicht/chezmoi
- Verification command assuming deployed SSH configs (not present on fresh client Mac)
- Suboptimal step ordering (temp file → move instead of direct write)

All corrected via follow-up commits during checkpoint review cycle.

## User Setup Required

**The runbook itself IS the user setup guide.** User will follow RUNBOOK-02-bootstrap.md on the client Mac to:
1. Set up age encryption key (BOOT-01)
2. Clone chezmoi source repository (BOOT-02)
3. Run chezmoi init with client configuration (BOOT-03)

No automation scripts - this is a human-readable, step-by-step guide.

## Next Phase Readiness

Ready for Phase 28 (Migration). User has runbook to bootstrap client Mac infrastructure. After user completes RUNBOOK-02-bootstrap.md, Phase 28 will cover:
- Safe removal of Dotbot symlinks
- Running `chezmoi apply` to deploy dotfiles
- Post-migration verification

**Bootstrap verification command included in runbook** to confirm all prerequisites met before proceeding to Phase 28.

## Self-Check: PASSED

All referenced files and commits verified:
- FOUND: .planning/phases/27-bootstrap/RUNBOOK-02-bootstrap.md
- FOUND: .planning/phases/27-bootstrap/27-01-SUMMARY.md
- FOUND: All commits (e3bcc17, e4169ea, b061cf7, e56d23b, 13384de)

---
*Phase: 27-bootstrap*
*Completed: 2026-02-15*
