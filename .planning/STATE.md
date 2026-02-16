# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-15)

**Core value:** Cross-platform dotfiles that "just work" -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.
**Current focus:** v3.0 Client Migration -- COMPLETE

## Current Position

Phase: 31 of 31 (Rollback Documentation)
Plan: 1 of 1 in current phase (Phase 31 complete)
Status: v3.0 milestone complete
Last activity: 2026-02-16 -- Completed 31-01-PLAN.md (Rollback runbook)

Progress: [████████████████████████] 100% (31/31 phases completed)

## Performance Metrics

**Velocity:**
- Total plans completed: 63
- Average duration: 7.46 min
- Total execution time: 7.76 hours

**By Milestone:**

| Milestone | Phases | Plans | Total | Avg/Plan |
|-----------|--------|-------|-------|----------|
| v1.0.0 | 6 | 25 | 3.10h | 7.4 min |
| v1.1 | 6 | 13 | 1.35h | 6.2 min |
| v1.2 | 6 | 7 | 0.82h | 7.0 min |
| v2.0 | 4 | 8 | 0.48h | 3.6 min |
| v2.1 | 3 | 4 | 0.14h | 2.1 min |
| v3.0 | 6 | 6 | 1.87h | 18.7 min |

**Overall:** 31 phases, 63 plans, 5 milestones in 23 days (2026-01-25 to 2026-02-16)

**Recent executions:**
| Phase | Duration | Tasks | Files |
|-------|----------|-------|-------|
| 27-01 | 33 min | 2 | 1 |
| 28-01 | 35 min | 2 | 1 |
| 29-01 | 6 min | 2 | 1 |
| 30-01 | 4 min | 2 | 1 |
| 31-01 | 30 min | 2 | 1 |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting v3.0 work:

- Phase 14: Machine-type conditional template pattern (`{{- if eq .machine_type "client" }}`) for client-only configs
- Phase 20: Evalcache for static tool init calls (skip dynamic like mise)
- Phase 23: File-based mise tasks with chezmoi deployment via executable_ prefix
- Phase 25: Hybrid AI/manual mode for git workflows with remote-aware PR creation
- Phase 26: Audit captures state in ~/migration-audit/ directory rather than in dotfiles repo to avoid accidental commits of sensitive data
- Phase 27: HTTPS clone for initial chezmoi setup (SSH keys encrypted in repo), age key in Bitwarden shared folder, verification via chezmoi diff
- Phase 28: Symlink materialisation approach (cp -L with backup before rm), dry-run first apply strategy, conflict categorisation (safe to overwrite/merge needed/keep local), SSH remote switch after key deployment
- [Phase 29]: Script triage uses chezmoi add with .chezmoiignore for machine-type conditionals
- [Phase 29]: Environment variables reintegrated either via chezmoi templates (stable client-specific values) or local override file (secrets/ephemeral values)
- [Phase 29]: Config merges support three approaches: manual edit, chezmoi merge, and source overwrite
- [Phase 31]: Rollback decision criteria: three severity categories (Debug Forward for single-subsystem issues, Consider Rollback for multiple failures, Rollback Immediately for time pressure/data loss)
- [Phase 31]: Procedure ordering: Decision criteria placed first before rollback steps so users consult framework before acting
- [Phase 31]: Safety strategy: Keep dotfiles-zsh repo for 2 weeks post-verification, preserve migration-audit directory

### Pending Todos

None.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-02-16 (Phase 31 execution)
Stopped at: Completed 31-01-PLAN.md (Rollback runbook) - v3.0 milestone COMPLETE
Resume file: None

**Next action:** User executes Phases 26-31 runbooks on client Mac to perform the migration. All 6 runbooks (RUNBOOK-01 through RUNBOOK-06) are ready. Keep RUNBOOK-06-rollback.md accessible as safety net during migration.
