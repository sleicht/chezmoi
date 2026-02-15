# Roadmap: Dotfiles Stack

## Milestones

- ✅ **v1.0.0 Dotfiles Stack Migration** -- Phases 1-6 (shipped 2026-02-08)
- ✅ **v1.1 Complete Migration** -- Phases 7-12 (shipped 2026-02-12)
- ✅ **v1.2 Legacy Cleanup** -- Phases 13-18 (shipped 2026-02-14)
- ✅ **v2.0 Performance** -- Phases 19-22 (shipped 2026-02-14)
- ✅ **v2.1 Mise Task Runner** -- Phases 23-25 (shipped 2026-02-15)

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

### v2.1 Mise Task Runner (In Progress)

**Milestone Goal:** Implement mise task runner for dotfiles operations and development workflows, providing user-friendly commands for chezmoi operations, verification workflows, and conventional git commits.

#### Phase 23: Task Infrastructure
**Goal**: Establish mise task directory structure and deployment pipeline
**Depends on**: Phase 22
**Requirements**: INFRA-01, INFRA-02, INFRA-03, INFRA-04, INFRA-05
**Success Criteria** (what must be TRUE):
  1. Task files deploy from chezmoi source to ~/.config/mise/tasks/ with executable permissions
  2. mise tasks command shows all available tasks with descriptions
  3. Tasks namespaced by subdirectory structure (dotfiles:apply, git:commit)
  4. Task aliases work for common commands (mise run a for dotfiles:apply)
  5. Expensive tasks skip when sources unchanged via rebuild detection
**Plans:** 1 plan

Plans:
- [x] 23-01-PLAN.md -- Create task directory structure with stub tasks, deploy and verify all INFRA requirements -- completed 2026-02-14

#### Phase 24: Dotfiles Operations
**Goal**: Wrap dotfiles workflows as mise tasks for user-friendly commands
**Depends on**: Phase 23
**Requirements**: DOT-01, DOT-02, DOT-03, DOT-04, DOT-05, DOT-06
**Success Criteria** (what must be TRUE):
  1. User can run dotfiles:apply to deploy configs with verbose output
  2. User can run dotfiles:verify to check all 112 verification rules
  3. User can run dotfiles:smoke-test to validate shell functionality
  4. User can run dotfiles:diff to preview changes before applying
  5. User can run dotfiles:update to pull and apply in one command
  6. User can run dotfiles:sync to backup, pull, apply, and verify in single workflow
**Plans:** 1 plan

Plans:
- [x] 24-01-PLAN.md -- Implement all six dotfiles operation tasks (apply, verify, smoke-test, diff, update, sync) -- completed 2026-02-14

#### Phase 25: Git Workflow Tasks
**Goal**: Provide git helpers enforcing conventional commits and branch naming
**Depends on**: Phase 24
**Requirements**: GIT-01, GIT-02, GIT-03, GIT-04
**Success Criteria** (what must be TRUE):
  1. User can run git:commit to create conventional commit with Jira ticket prefix
  2. User can run git:branch to create feature branch following naming convention
  3. User can run git:cleanup to prune merged local branches
  4. User can run git:pr to create pull request with template via gh CLI
  5. Shell startup time remains under 300ms with mise activation enabled
**Plans:** 2 plans

Plans:
- [x] 25-01-PLAN.md -- Implement git:commit and git:branch tasks (interactive commit + branch creation) -- completed 2026-02-15
- [x] 25-02-PLAN.md -- Implement git:cleanup and git:pr tasks (branch pruning + PR creation) -- completed 2026-02-15

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Nix Removal | v1.0.0 | 4/4 | Complete | 2026-01-25 |
| 2. Chezmoi Foundation | v1.0.0 | 5/5 | Complete | 2026-01-28 |
| 3. Runtime Management Migration | v1.0.0 | 4/4 | Complete | 2026-01-30 |
| 4. Homebrew Automation | v1.0.0 | 4/4 | Complete | 2026-02-02 |
| 5. Secret Management | v1.0.0 | 4/4 | Complete | 2026-02-05 |
| 6. Security & Verification | v1.0.0 | 4/4 | Complete | 2026-02-08 |
| 7. Preparation | v1.1 | 2/2 | Complete | 2026-02-08 |
| 8. Basic Configs & CLI Tools | v1.1 | 3/3 | Complete | 2026-02-11 |
| 9. Terminal Emulators | v1.1 | 2/2 | Complete | 2026-02-09 |
| 10. Dev Tools with Secrets | v1.1 | 2/2 | Complete | 2026-02-10 |
| 11. Claude Code | v1.1 | 2/2 | Complete | 2026-02-12 |
| 12. Dotbot Retirement | v1.1 | 2/2 | Complete | 2026-02-12 |
| 13. Remove Legacy Config Files | v1.2 | 2/2 | Complete | 2026-02-13 |
| 14. Migrate san-proxy to chezmoi | v1.2 | 1/1 | Complete | 2026-02-14 |
| 15. Fix PATH and Version Manager Code | v1.2 | 1/1 | Complete | 2026-02-14 |
| 16. Fix Python 2 and Shell Utilities | v1.2 | 1/1 | Complete | 2026-02-14 |
| 17. Clean Audit Scripts and Artifacts | v1.2 | 1/1 | Complete | 2026-02-14 |
| 18. Clean Tech Debt from Audit | v1.2 | 1/1 | Complete | 2026-02-14 |
| 19. Baseline & Quick Wins | v2.0 | 2/2 | Complete | 2026-02-14 |
| 20. Eval Caching Layer | v2.0 | 2/2 | Complete | 2026-02-14 |
| 21. Sync/Defer Architecture Split | v2.0 | 2/2 | Complete | 2026-02-14 |
| 22. Monitoring & Hardening | v2.0 | 2/2 | Complete | 2026-02-14 |
| 23. Task Infrastructure | v2.1 | 1/1 | Complete | 2026-02-14 |
| 24. Dotfiles Operations | v2.1 | 1/1 | Complete | 2026-02-14 |
| 25. Git Workflow Tasks | v2.1 | 2/2 | Complete | 2026-02-15 |

---
*Last updated: 2026-02-15 -- Phase 25 complete (2/2 plans)*
