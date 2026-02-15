# Roadmap: Dotfiles Stack

## Milestones

- ✅ **v1.0.0 Dotfiles Stack Migration** -- Phases 1-6 (shipped 2026-02-08)
- ✅ **v1.1 Complete Migration** -- Phases 7-12 (shipped 2026-02-12)
- ✅ **v1.2 Legacy Cleanup** -- Phases 13-18 (shipped 2026-02-14)
- ✅ **v2.0 Performance** -- Phases 19-22 (shipped 2026-02-14)
- ✅ **v2.1 Mise Task Runner** -- Phases 23-25 (shipped 2026-02-15)
- 🚧 **v3.0 Client Migration** -- Phases 26-31 (in progress)

## Phases

<details>
<summary>✅ v1.0.0 Dotfiles Stack Migration (Phases 1-6) -- SHIPPED 2026-02-08</summary>

Complete migration from Nix/Dotbot/Zgenom/asdf to chezmoi/mise/Homebrew/Sheldon with cross-platform templating and Bitwarden secret management. See `.planning/milestones/v1.0.0-ROADMAP.md` for full details.

**Stats:** 6 phases, 25 plans, 3.10 hours total execution time

- [x] Phase 1: Nix Removal (4/4 plans) -- completed 2026-01-25
- [x] Phase 2: Chezmoi Foundation (5/5 plans) -- completed 2026-01-28
- [x] Phase 3: Runtime Management Migration (4/4 plans) -- completed 2026-01-30
- [x] Phase 4: Homebrew Automation (4/4 plans) -- completed 2026-02-02
- [x] Phase 5: Secret Management (4/4 plans) -- completed 2026-02-05
- [x] Phase 6: Security & Verification (4/4 plans) -- completed 2026-02-08

</details>

<details>
<summary>✅ v1.1 Complete Migration (Phases 7-12) -- SHIPPED 2026-02-12</summary>

Migrated all remaining Dotbot-managed configs to chezmoi and retired Dotbot entirely. 69 config files migrated with 112 automated verification checks. See `.planning/milestones/v1.1-ROADMAP.md` for full details.

**Stats:** 6 phases, 13 plans, 57 commits, 30/30 requirements satisfied

- [x] Phase 7: Preparation (2/2 plans) -- completed 2026-02-08
- [x] Phase 8: Basic Configs & CLI Tools (3/3 plans) -- completed 2026-02-11
- [x] Phase 9: Terminal Emulators (2/2 plans) -- completed 2026-02-09
- [x] Phase 10: Dev Tools with Secrets (2/2 plans) -- completed 2026-02-10
- [x] Phase 11: Claude Code (2/2 plans) -- completed 2026-02-12
- [x] Phase 12: Dotbot Retirement (2/2 plans) -- completed 2026-02-12

</details>

<details>
<summary>✅ v1.2 Legacy Cleanup (Phases 13-18) -- SHIPPED 2026-02-14</summary>

Removed all pre-chezmoi artifacts from the repository and fixed stale code in the chezmoi source. Net -16,609 lines removed. See `.planning/milestones/v1.2-ROADMAP.md` for full details.

**Stats:** 6 phases, 7 plans, 40 commits, 19/21 requirements satisfied (2 rescinded)

- [x] Phase 13: Remove Legacy Config Files (2/2 plans) -- completed 2026-02-13
- [x] Phase 14: Migrate san-proxy to chezmoi (1/1 plan) -- completed 2026-02-14
- [x] Phase 15: Fix PATH and Version Manager Code (1/1 plan) -- completed 2026-02-14
- [x] Phase 16: Fix Python 2 and Shell Utilities (1/1 plan) -- completed 2026-02-14
- [x] Phase 17: Clean Audit Scripts and Artifacts (1/1 plan) -- completed 2026-02-14
- [x] Phase 18: Clean Tech Debt from Audit (1/1 plan) -- completed 2026-02-14

</details>

<details>
<summary>✅ v2.0 Performance (Phases 19-22) -- SHIPPED 2026-02-14</summary>

Achieved 139.8ms shell startup (55.6% faster than 314.6ms baseline, 53.4% better than 300ms target) through eval caching, sync/defer architecture, and startup monitoring. See `.planning/milestones/v2.0-ROADMAP.md` for full details.

**Stats:** 4 phases, 8 plans, 27 commits, 22/23 requirements satisfied (1 acceptable)

- [x] Phase 19: Baseline & Quick Wins (2/2 plans) -- completed 2026-02-14
- [x] Phase 20: Eval Caching Layer (2/2 plans) -- completed 2026-02-14
- [x] Phase 21: Sync/Defer Architecture Split (2/2 plans) -- completed 2026-02-14
- [x] Phase 22: Monitoring & Hardening (2/2 plans) -- completed 2026-02-14

</details>

<details>
<summary>✅ v2.1 Mise Task Runner (Phases 23-25) -- SHIPPED 2026-02-15</summary>

Implemented mise task runner for dotfiles operations and git workflows with 10 user-friendly commands, hybrid AI/manual mode for git operations, and short aliases. See `.planning/milestones/v2.1-ROADMAP.md` for full details.

**Stats:** 3 phases, 4 plans, 15 commits, 15/15 requirements satisfied

- [x] Phase 23: Task Infrastructure (1/1 plan) -- completed 2026-02-14
- [x] Phase 24: Dotfiles Operations (1/1 plan) -- completed 2026-02-14
- [x] Phase 25: Git Workflow Tasks (2/2 plans) -- completed 2026-02-15

</details>

### v3.0 Client Migration (In Progress)

**Milestone Goal:** Produce a step-by-step runbook for migrating the client macOS from the frozen dotfiles-zsh (Dotbot) repo to the chezmoi-managed stack, including local state capture, age key bootstrap, symlink-to-real-file transition, and post-migration verification.

#### Phase 26: Pre-Migration Audit
**Goal**: Document procedures for capturing local state before migration
**Depends on**: Nothing (first phase of milestone)
**Requirements**: AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04
**Success Criteria** (what must be TRUE):
  1. User can list all Dotbot symlinks and their targets to identify what will be replaced
  2. User can identify custom scripts and bins not tracked in either repo for preservation
  3. User can capture machine-specific environment variables unique to the client Mac
  4. User can diff drifted configs against the old repo to identify valuable local edits
**Plans**: 1 plan

Plans:
- [x] 26-01-PLAN.md -- Pre-migration audit runbook (4 procedures: symlinks, custom scripts, env vars, config drift)

#### Phase 27: Bootstrap
**Goal**: Document procedures for setting up chezmoi infrastructure on client Mac
**Depends on**: Phase 26
**Requirements**: BOOT-01, BOOT-02, BOOT-03
**Success Criteria** (what must be TRUE):
  1. User can generate an age encryption key and securely store its public key in Bitwarden
  2. User can clone the chezmoi source repo to the expected location on client Mac
  3. User can run chezmoi init with correct machine_type, email, and encryption settings
**Plans**: 1 plan

Plans:
- [x] 27-01-PLAN.md -- Bootstrap runbook (3 procedures: age key setup, repo clone, chezmoi init)

#### Phase 28: Migration
**Goal**: Document procedures for safe Dotbot removal and chezmoi deployment
**Depends on**: Phase 27
**Requirements**: MIG-01, MIG-02, MIG-03
**Success Criteria** (what must be TRUE):
  1. User can safely convert Dotbot symlinks to real files before running chezmoi apply
  2. User can execute chezmoi apply with client-specific templates correctly rendered
  3. User has a documented conflict resolution procedure for pre-existing files
**Plans**: 1 plan

Plans:
- [ ] 28-01-PLAN.md -- Migration runbook (3 procedures: symlink materialisation, chezmoi apply, conflict resolution)

#### Phase 29: Reintegration
**Goal**: Document procedures for merging captured local tweaks into chezmoi
**Depends on**: Phase 28
**Requirements**: REINT-01, REINT-02, REINT-03
**Success Criteria** (what must be TRUE):
  1. User can evaluate custom scripts and decide: add to chezmoi, keep local, or discard
  2. User can reintegrate machine-specific env vars via templates or local override files
  3. User can merge valuable config edits from drifted files into chezmoi source
**Plans**: 1 plan

Plans:
- [ ] 29-01-PLAN.md -- Reintegration runbook (3 procedures: script triage, env var reintegration, config merge)

#### Phase 30: Verification
**Goal**: Document procedures for confirming migration success
**Depends on**: Phase 29
**Requirements**: VERIF-01, VERIF-02, VERIF-03, VERIF-04
**Success Criteria** (what must be TRUE):
  1. User can verify shell functionality: aliases work, prompt renders, plugins load
  2. User can verify git workflows: commits work, mise tasks function, hooks trigger
  3. User can verify tool availability: mise runtimes respond, Homebrew packages exist, keys decrypt
  4. User can run the 13-check smoke test script and all checks pass
**Plans**: 1 plan

Plans:
- [ ] 30-01-PLAN.md -- Verification runbook (4 procedures: shell functionality, git workflows, tool availability, smoke test)

#### Phase 31: Rollback Documentation
**Goal**: Document safety net procedures for reverting to old Dotbot setup
**Depends on**: Phase 30
**Requirements**: ROLL-01, ROLL-02
**Success Criteria** (what must be TRUE):
  1. User has step-by-step rollback instructions to restore Dotbot symlinks from old repo
  2. User has decision criteria for when to rollback vs. debug forward
**Plans**: 1 plan

Plans:
- [ ] 31-01-PLAN.md -- Rollback runbook (2 procedures: rollback decision criteria, Dotbot symlink restoration)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Nix Removal | v1.0.0 | 4/4 | Complete | 2026-01-25 |
| 2. Chezmoi Foundation | v1.0.0 | 5/5 | Complete | 2026-01-28 |
| 3. Runtime Management | v1.0.0 | 4/4 | Complete | 2026-01-30 |
| 4. Homebrew Automation | v1.0.0 | 4/4 | Complete | 2026-02-02 |
| 5. Secret Management | v1.0.0 | 4/4 | Complete | 2026-02-05 |
| 6. Security & Verification | v1.0.0 | 4/4 | Complete | 2026-02-08 |
| 7. Preparation | v1.1 | 2/2 | Complete | 2026-02-08 |
| 8. Basic Configs & CLI | v1.1 | 3/3 | Complete | 2026-02-11 |
| 9. Terminal Emulators | v1.1 | 2/2 | Complete | 2026-02-09 |
| 10. Dev Tools with Secrets | v1.1 | 2/2 | Complete | 2026-02-10 |
| 11. Claude Code | v1.1 | 2/2 | Complete | 2026-02-12 |
| 12. Dotbot Retirement | v1.1 | 2/2 | Complete | 2026-02-12 |
| 13. Legacy Config Files | v1.2 | 2/2 | Complete | 2026-02-13 |
| 14. san-proxy Migration | v1.2 | 1/1 | Complete | 2026-02-14 |
| 15. PATH/Version Manager Fix | v1.2 | 1/1 | Complete | 2026-02-14 |
| 16. Python 2/Shell Utilities | v1.2 | 1/1 | Complete | 2026-02-14 |
| 17. Audit Scripts Cleanup | v1.2 | 1/1 | Complete | 2026-02-14 |
| 18. Tech Debt Cleanup | v1.2 | 1/1 | Complete | 2026-02-14 |
| 19. Baseline & Quick Wins | v2.0 | 2/2 | Complete | 2026-02-14 |
| 20. Eval Caching Layer | v2.0 | 2/2 | Complete | 2026-02-14 |
| 21. Sync/Defer Architecture | v2.0 | 2/2 | Complete | 2026-02-14 |
| 22. Monitoring & Hardening | v2.0 | 2/2 | Complete | 2026-02-14 |
| 23. Task Infrastructure | v2.1 | 1/1 | Complete | 2026-02-14 |
| 24. Dotfiles Operations | v2.1 | 1/1 | Complete | 2026-02-14 |
| 25. Git Workflow Tasks | v2.1 | 2/2 | Complete | 2026-02-15 |
| 26. Pre-Migration Audit | v3.0 | 1/1 | Complete | 2026-02-15 |
| 27. Bootstrap | v3.0 | 1/1 | Complete | 2026-02-15 |
| 28. Migration | v3.0 | Complete    | 2026-02-15 | - |
| 29. Reintegration | v3.0 | Complete    | 2026-02-15 | - |
| 30. Verification | v3.0 | Complete    | 2026-02-15 | - |
| 31. Rollback Documentation | v3.0 | 0/1 | Planned | - |

---
*Last updated: 2026-02-15 -- Phase 31 planned (1 plan)*
