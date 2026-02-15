# Roadmap: Dotfiles Stack

## Milestones

- ✅ **v1.0.0 Dotfiles Stack Migration** -- Phases 1-6 (shipped 2026-02-08)
- ✅ **v1.1 Complete Migration** -- Phases 7-12 (shipped 2026-02-12)
- 🔧 **v1.2 Legacy Cleanup** -- Phases 13-18 (in progress)
- 📋 **v2.0 Performance** -- Phases TBD (planned)

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

### v1.2 Legacy Cleanup (In Progress)

**Milestone Goal:** Remove all pre-chezmoi artifacts from the repo and fix stale code in the chezmoi source, so the repository reflects reality.

#### Phase 13: Remove Legacy Config Files ✓
**Goal**: Clean Dotbot-era artifacts from repository
**Depends on**: Phase 12 (Dotbot retired)
**Requirements**: LEGACY-01, LEGACY-02, LEGACY-04, LEGACY-05
**Success Criteria** (what must be TRUE):
  1. ✓ Repository contains no .config/ directories from Dotbot era (10 directories removed)
  2. ✓ Repository contains no .config/ flat files from Dotbot era (17 files removed)
  3. ✓ Repository contains no redundant zsh.d/ directory (chezmoi manages dot_zsh.d/)
  4. ✓ Repository contains no legacy Brewfiles (3 files removed, .chezmoidata.yaml is sole source)
**Plans**: 2 plans
**Note**: Also removed 7 legacy verification/backup scripts (pulled forward from Phase 17 scope)

Plans:
- [x] 13-01-PLAN.md -- Scan repository for legacy file references
- [x] 13-02-PLAN.md -- Remove all legacy files (5 commits: scripts + 4 categories)

#### Phase 14: Migrate san-proxy to chezmoi ✓
**Goal**: san-proxy sourcing managed by chezmoi with client-only template
**Depends on**: Phase 13 (clean separation from legacy .config/profile)
**Requirements**: LEGACY-03
**Success Criteria** (what must be TRUE):
  1. ✓ san-proxy sourcing removed from legacy .config/profile
  2. ✓ san-proxy sourcing added to chezmoi source with client-only conditional
  3. ✓ Client machine sources san-proxy, personal machine does not
**Plans:** 1 plan

Plans:
- [x] 14-01-PLAN.md -- Template zshrc with client-only san-proxy and clean up legacy profile

#### Phase 15: Fix PATH and Version Manager Code ✓
**Goal**: Remove stale version manager code from chezmoi source
**Depends on**: Nothing (works on chezmoi source)
**Requirements**: ~~CHEZFIX-01~~, ~~CHEZFIX-02~~, CHEZFIX-03, CHEZFIX-04, CHEZFIX-09, CHEZFIX-10
**Success Criteria** (what must be TRUE):
  1. ✓ ~~chezmoi path.zsh contains no Volta or rbenv PATH entries~~ — RESCINDED: Volta and rbenv kept unconditionally (add_to_path guards missing dirs)
  2. ✓ chezmoi variables.zsh contains no hardcoded npm PATH or empty version manager section
  3. ✓ mise activation occurs once in external.zsh (not duplicated in hooks.zsh)
  4. ✓ chezmoi hooks.zsh contains no commented-out asdf activation
**Plans**: 1 plan

Plans:
- [x] 15-01-PLAN.md -- Remove stale Volta, rbenv, asdf, and duplicate mise code from chezmoi source

#### Phase 16: Fix Python 2 and Shell Utilities ✓
**Goal**: Modernize Python 3 usage and shell aliases in chezmoi source
**Depends on**: Nothing (independent fixes)
**Requirements**: CHEZFIX-05, CHEZFIX-06, CHEZFIX-07, CHEZFIX-08
**Success Criteria** (what must be TRUE):
  1. ✓ server() function uses Python 3 http.server (not Python 2 SimpleHTTPServer)
  2. ✓ urlencode alias uses Python 3 urllib.parse (not Python 2 urllib)
  3. ✓ omz reload alias uses exec shell reload (not stale omz command)
  4. ✓ update alias contains no stale npm/gem commands (mise handles these)
**Plans**: 1 plan

Plans:
- [x] 16-01-PLAN.md -- Fix Python 2 code, stale omz reload, and npm/gem commands

#### Phase 17: Clean Audit Scripts and Artifacts ✓
**Goal**: Remove stale directories and fix audit script references
**Depends on**: Phase 13 (references to removed directories)
**Requirements**: MISC-01, MISC-02, MISC-03, MISC-04, MISC-05, MISC-06
**Success Criteria** (what must be TRUE):
  1. ✓ Repository contains no empty bin/ or logs/ directories
  2. ✓ Repository contains no firebase-debug.log (added to .gitignore)
  3. ✓ audit-gitleaks.toml contains no references to dotbot/zgenom directories
  4. ✓ audit-secrets.sh contains no references to dotbot directory
  5. ~~verify-backup.sh critical files list reflects chezmoi layout~~ (DONE: script removed in Phase 13)
**Plans**: 1 plan

Plans:
- [x] 17-01-PLAN.md -- Remove stale directories/files, update .gitignore, fix audit script references

#### Phase 18: Clean Tech Debt from Audit ✓
**Goal**: Delete orphaned files and obsolete scripts identified by milestone audit
**Depends on**: Phase 17 (audit identified these items)
**Requirements**: None (tech debt cleanup)
**Success Criteria** (what must be TRUE):
  1. ✓ Repository contains no `.config/profile` or empty `.config/` directory
  2. ✓ Repository contains no `audit-report-*.md` files in `scripts/`
  3. ✓ Repository contains no obsolete verify-checks (`11-claude-code.sh`, `12-dotbot-retirement.sh`)
  4. ✓ `scripts/test-linux.sh` reviewed and removed if unused
  5. ✓ `.gitignore` prevents future `audit-report-*.md` accumulation
**Plans**: 1 plan

Plans:
- [x] 18-01-PLAN.md -- Delete orphaned files, obsolete scripts, update .gitignore

### v2.0 Performance (Planned)

**Milestone Goal:** Optimize shell startup time to < 300ms and add mise task runner.

Phases TBD.

## Progress

**Execution Order:**
Phases execute in numeric order: 13 -> 14 -> 15 -> 16 -> 17 -> 18

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

---
*Last updated: 2026-02-14 after Phase 18 complete — v1.2 Legacy Cleanup milestone shipped*
