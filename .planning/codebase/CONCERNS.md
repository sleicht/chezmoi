# Codebase Concerns

**Analysis Date:** 2026-02-15

## Tech Debt

### 🔴 High: Large monolithic data file

**Issue:** `.chezmoidata.yaml` at 291 lines contains all package lists, with no separation by concern.

**Files:** `.chezmoidata.yaml`

**Impact:**
- Hard to navigate and maintain when adding packages
- Single source of truth means any error blocks all machines
- Difficult to review changes in diffs (machine-specific lists mixed together)
- No way to version or document package groups separately

**Fix approach:**
- Split into separate files by package category: `packages/darwin-taps.yaml`, `packages/darwin-brews.yaml`, `packages/darwin-casks.yaml`, etc.
- Reduce main data file to ~150 lines of metadata
- Makes machine-specific diffs clearer and easier to review

---

### 🟡 Medium: Complex ignore rules

**Issue:** `.chezmoiignore` at 222 lines uses 11 sections with conditional template logic and overlapping patterns.

**Files:** `.chezmoiignore`

**Impact:**
- Hard to understand which files deploy on which machines
- Template conditionals (`{{- if ne .chezmoi.os "darwin" }}`) can fail silently if chezmoi context changes
- Future migrations (Phase 12) require manual removal of ignore patterns
- Difficult to reason about what actually gets deployed

**Fix approach:**
- Create separate ignore files per phase or concern (e.g., `.chezmoiignore-claude-local`, `.chezmoiignore-meta-only`)
- Document deployment status for every section in comments with dates
- Convert to a manifest-based approach: explicit list of what SHOULD deploy rather than what shouldn't
- Automate removal of phase-specific sections when those phases complete

---

### 🟡 Medium: Hardcoded Homebrew paths

**Issue:** Scripts rely on `/opt/homebrew` hardcoded in multiple places, which is ARM64-specific.

**Files:**
- `dot_profile.tmpl` (lines 27-29)
- `run_once_before_setup-bw-wrapper.sh.tmpl` (line 22)
- `run_once_before_setup-phantom-wrapper.sh.tmpl` (line 22)
- `private_dot_gnupg/gpg-agent.conf.tmpl` (pinentry-program)
- `run_once_before_install-homebrew.sh.tmpl` (line 8)

**Impact:**
- Won't work on Intel Macs (`/usr/local/opt/homebrew`)
- Breaks on Linux with Homebrew (different paths)
- Wrapper scripts assume node lives at specific Homebrew path
- GPG pinentry hardcoded to macOS Homebrew location

**Fix approach:**
- Use `$(brew --prefix)` instead of hardcoding `/opt/homebrew`
- Detect Homebrew installation dynamically in setup scripts
- Store Homebrew prefix in `.chezmoi.yaml.tmpl` as computed variable during init
- Make GPG agent config conditional and discover pinentry location

---

## Security Considerations

### 🔴 High: Age identity key location not enforced at setup

**Issue:** Age identity key expected at `~/.config/age/key-{{ .machine_type }}.txt` but setup doesn't verify it exists before `chezmoi apply`.

**Files:** `.chezmoi.yaml.tmpl` (line 32)

**Current mitigation:** `.chezmoiignore` excludes `.config/age` from deployment (correct, keys must pre-exist)

**Recommendations:**
- Add verification to `run_once_before_install-homebrew.sh.tmpl` to check age key exists
- If missing, print clear error message with recovery steps (bootstrap with manual key import)
- Prevent chezmoi from proceeding if age key is absent
- Document in README: "Age identity key must be created manually before first apply"

---

### 🟡 Medium: Private SSH keys stored in Git (encrypted)

**Issue:** SSH private keys stored in `private_dot_ssh/encrypted_*.age` including personal keys for 4 different hosts.

**Files:** `private_dot_ssh/encrypted_private_id_rsa*.age` (4 files)

**Current mitigation:**
- Files encrypted with age
- `.chezmoiignore` prevents deployment of age identity keys themselves
- Gitleaks configured to allow age public keys only

**Recommendations:**
- Add pre-commit hook to prevent accidental decryption or unencrypted key commits
- Document key rotation procedure (currently no lifecycle documented)
- Add expiry check in setup script (warn if keys >2 years old)
- Consider using SSH agent forwarding instead of deploying keys on every machine
- Add metadata file tracking which servers each key is authorized on

---

### 🟡 Medium: Bitwarden CLI wrapper security gap

**Issue:** Wrapper at `~/.local/bin/bw` injects node path to work around Homebrew shebang issues.

**Files:** `run_once_before_setup-bw-wrapper.sh.tmpl`

**Impact:**
- Wrapper created on every apply (even if bw hasn't moved)
- Script doesn't verify wrapper permissions after creation
- If node binary is replaced, wrapper could execute malicious code
- No verification that `/opt/homebrew/bin/bw` is legitimate Homebrew binary

**Fix approach:**
- Add checksum verification of original bw binary
- Only create wrapper if it doesn't exist (change `run_once_` to `run_onchange_` with checksum)
- Fix permissions immediately after wrapper creation (don't rely on later verify script)
- Document why this wrapper is necessary and how to detect if Homebrew fixes the issue

---

## Maintainability Issues

### 🟡 Medium: No recovery procedure for failed apply

**Issue:** If `chezmoi apply` fails mid-execution, unclear how to recover without manual intervention.

**Files:** All `run_*` scripts

**Impact:**
- Package installation could be partially complete
- Some permissions fixed, others not
- Permissions verification script runs every apply (not idempotent for cleanup)
- No rollback or state tracking

**Fix approach:**
- Add explicit error state file: `~/.local/state/chezmoi/apply-state.json` tracking which phases succeeded
- Document recovery: "Run `chezmoi apply` again to resume from last failure point"
- Make all scripts idempotent and resumable
- Add `chezmoi apply --backup` option to store pre-apply snapshot

---

## Fragile Areas

### 🟡 Medium: Package list maintenance at scale

**Files:** `.chezmoidata.yaml` (lines 5-250)

**Why fragile:**
- 100+ packages across common, client, and fanaka lists
- No grouping by purpose (dev tools, design apps, utilities)
- Duplicates possible but undetected (e.g., appears both in common_brews and client_brews)
- Package removal requires knowing which machine list it's on

**Safe modification:**
- Before adding: check if already in common/fanaka/client lists via grep
- Test on same machine type before applying elsewhere
- Use `chezmoi diff` to verify Brewfile changes before apply
- Test coverage: zero test files for Brewfile generation

**Test coverage gaps:**
- No validation that all listed packages exist in Homebrew
- No detection of circular dependencies or conflicts
- Package list never validated at apply time

---

### 🟡 Medium: Template generation complexity

**Files:**
- `dot_Brewfile.tmpl` (55 lines, but generates 200+ lines of output)
- `dot_zshrc.tmpl` (65 lines with nested conditionals)
- `dot_profile.tmpl` (122 lines with multiple OS conditionals)

**Why fragile:**
- Nested template logic (`{{ if }} {{ range }} {{ if }}`) hard to follow
- No test harness for rendered output
- Changes to logic require manual verification of final files
- Errors in template syntax silently produce empty output

**Safe modification:**
- Always use `chezmoi diff` before apply
- Render templates locally: `chezmoi execute-template < dot_zshrc.tmpl`
- Create test templates with minimal data before modifying production
- Add syntax validation in CI (chezmoi has `--validate` flag)

---

## Scaling Limits

### 🟡 Medium: Package growth unsustainable

**Current capacity:** 100+ Homebrew packages, 30+ casks, 10+ Mac App Store apps

**Limit:** Data file becomes unreadable beyond ~150 packages without reorganisation

**Scaling path:**
- Split packages file by category (dev tools, design, utilities, security)
- Implement package versioning constraints
- Add package "profiles" (minimal, standard, full)
- Allow users to opt-in/out of categories

---

### 🟡 Medium: Lifecycle scripts running every apply

**Issue:** Run scripts execute on every `chezmoi apply`:
- `run_after_10-verify-permissions.sh` checks ~30 paths every time
- `run_onchange_after_03-clear-evalcache.sh` runs even if eval cache unchanged

**Impact:** Adds 2-5 seconds to every apply, slows feedback loop during config iteration

**Improvement path:**
- Move non-critical checks to separate `chezmoi verify` command
- Cache permission check results if nothing changed
- Document which scripts run every apply vs. once-only

---

## Cross-Platform Support

### 🔴 High: Linux support incomplete

**Files:** Multiple scripts and config files use `{{ if eq .chezmoi.os "darwin" }}`

**Current limitations:**
- `.chezmoidata.yaml` only has `darwin:` section (no Linux package lists)
- GPG config template branches only for darwin/linux, but pinentry discovery incomplete
- SSH key permissions verified for all, but Homebrew wrappers Linux-specific
- Brewfile generation skips entirely on non-Darwin (renders as empty)
- `.chezmoiignore` references macOS-only paths (AeroSpace, Finicky)

**Status:** Repository positions itself as personal (macOS) but has some Linux plumbing

**Recommendation:**
- Either: Make Linux first-class and add `packages.linux:` section to `.chezmoidata.yaml`
- Or: Explicitly document as "macOS only" and remove misleading Linux conditionals

---

## Testing & Validation

### 🔴 High: Zero automated validation

**Issue:** No test suite for configuration generation or deployment.

**What's not tested:**
- `.chezmoidata.yaml` structure (is it valid YAML? are all referenced packages valid?)
- Template rendering (do templates produce valid output?)
- Permission verification script (does it correctly detect/fix permissions?)
- Brewfile generation (is output valid for `brew bundle`?)
- Cross-platform logic (is Linux path correct if it were ever used?)

**Files:** `scripts/verify-configs.sh` exists but is manual inspection script, not automated

**Priority:** High — adds 5-10 minutes to any config change review

**Fix approach:**
- Add YAML schema validation for `.chezmoidata.yaml`
- Add bats-core test suite (already installed in fanaka_brews) with tests for:
  - Template rendering outputs valid files
  - Brewfile contains no duplicates
  - Permissions script correctly reads/writes on both macOS stat formats
  - Age encryption identity file exists before critical scripts run
- Run tests in CI on every commit

---

## Missing Critical Features

### 🟡 Medium: No configuration restore/rollback

**Issue:** There is no easy way to roll back to a known-good configuration state.

**Problem:** If `chezmoi apply` breaks something (e.g., removes needed package), no undo command

**Current workaround:** Manual git checkout + chezmoi apply, or restore from backup

**Blocks:** Confident experimentation with package lists

**Recommendation:**
- Add `chezmoi apply --backup` to save pre-apply state
- Implement `chezmoi rollback` to restore from backup
- Store backup in `~/.local/state/chezmoi/backups/`
- Auto-clean backups older than 7 days

---

### 🟡 Medium: No audit trail for applied configs

**Issue:** Can't easily see what changed between applies or when each config was deployed.

**Blocks:** Debugging "when did this break?" without git archaeology

**Recommendation:**
- Enhance `run_after_10-verify-permissions.sh.tmpl` to write full apply manifest: dates, files changed, permission fixes
- Store in `~/.local/state/chezmoi/apply-manifest.json` with entries per apply
- Provide `chezmoi history` command to show recent changes

---

## Specific Code Issues

### 🟡 Medium: Permission script uses glob expansion in array

**Issue:** In `run_after_10-verify-permissions.sh.tmpl` line 49, glob expansion happens at loop time, not array definition time.

**Files:** `run_after_10-verify-permissions.sh.tmpl` (line 49)

**Code:**
```bash
for file in $pattern; do
```

**Problem:** If pattern contains spaces or special chars, expansion is unpredictable

**Fix:** Use `eval` carefully or switch to find-based approach:
```bash
eval "for file in $pattern; do ... done"
```

---

### 🟡 Medium: Missing error messages in setup scripts

**Issue:** Wrapper setup scripts silently skip if tools don't exist.

**Files:**
- `run_once_before_setup-bw-wrapper.sh.tmpl` (line 15-17)
- `run_once_before_setup-phantom-wrapper.sh.tmpl`

**Code:**
```bash
if [[ ! -x "$BW_REAL" ]]; then
  echo "bw not found at $BW_REAL — skipping wrapper setup"
  exit 0
fi
```

**Problem:** User doesn't know wrappers weren't created; later commands fail mysteriously

**Fix:**
- Store list of skipped wrappers to `~/.local/state/chezmoi/skipped-wrappers.log`
- Print warning at end of apply: "N wrappers not created — check logs"
- Document: "If Homebrew packages are missing, run `chezmoi apply` again after installing them"

---

## Deployment & Environment

### 🟡 Medium: Manual age key bootstrap required but undocumented

**Issue:** Before first `chezmoi init`, user must manually create age identity key, but this is nowhere in setup docs.

**Files:** `.chezmoi.yaml.tmpl` expects key at `~/.config/age/key-{{ .machine_type }}.txt`

**Blocks:** First-time setup is opaque

**Recommendation:**
- Update README.md with explicit pre-requisite step
- Create `run_once_before_decrypt.sh` that checks for/creates age key
- Alternatively, generate key automatically if missing (less secure but more user-friendly)

---

### 🟡 Medium: No support for machine type changes

**Issue:** Once initialized with `machine_type: "personal"` or `machine_type: "client"`, can't switch without reinitializing.

**Impact:** Blocks workflow changes (personal → client for work, or vice versa)

**Fix approach:**
- Allow interactive `chezmoi init` to run again even after initial setup
- Provide `chezmoi config machine-type` command to switch types
- Re-generate relevant configs (Brewfile, etc.) when type changes

---

## Documentation Gaps

### 🟢 Low: Phase migration documentation incomplete

**Issue:** `.chezmoiignore` refers to "Phase 12" cleanup but no docs on which files will be removed.

**Files:** `.chezmoiignore` lines 200-210

**Fix approach:**
- Create `.planning/MIGRATION_PHASES.md` documenting each phase
- Link from README to migration guide
- Auto-remove phase ignore lines in CI when phase completes

---

## Summary by Priority

| Priority | Count | Themes |
|----------|-------|--------|
| 🔴 High | 3 | Age key bootstrap, Linux support incomplete, no test automation |
| 🟡 Medium | 13 | Data file scalability, hardcoded paths, deployment recovery, wrapper security |
| 🟢 Low | 1 | Migration phase docs |

**Biggest risk:** No automated validation means config changes could silently break deployments. Recommend implementing test suite immediately before next major config iteration.

---

*Concerns audit: 2026-02-15*
