# Testing Patterns

**Analysis Date:** 2026-02-15

## Quality Assurance Strategy

This dotfiles repository uses a **multi-gate validation approach** combining pre-commit hooks, lifecycle verification, drift detection, and smoke testing. Testing is integrated into deployment and operational workflows rather than traditional unit test suites.

## Pre-Commit Hooks

**Configuration:** `.pre-commit-config.yaml` (v4.4.0)

Pre-commit runs on two stages for comprehensive coverage:

**Install hooks:**
```bash
pre-commit install --hook-type pre-commit --hook-type pre-push
```

**Run all checks manually:**
```bash
pre-commit run --all-files
```

### Hook Suite

**1. Basic File Quality (pre-commit/pre-commit-hooks v4.4.0)**

| Hook | Purpose | Run Stage |
|------|---------|-----------|
| `check-yaml` | Validate YAML syntax (`.yaml`, `.yml`, `.posh.json`) | pre-commit, pre-push |
| `end-of-file-fixer` | Ensure files end with newline | pre-commit, pre-push |
| `trailing-whitespace` | Remove trailing spaces/tabs | pre-commit, pre-push |
| `check-merge-conflict` | Detect incomplete merge conflict markers | pre-commit, pre-push |

**2. Secret Scanning (gitleaks v8.24.2)**

- **Hook:** `id: gitleaks`
- **Config:** `.gitleaks.toml` (project-specific allowlist)
- **Stages:** pre-commit (warns), pre-push (blocks)
- **Arguments:** `--verbose --config .gitleaks.toml`

**How gitleaks works:**

Gitleaks inherits all built-in detection rules (`useDefault = true`) then applies:

**Allowlist (safe patterns to ignore):**
```regex
{{.*bitwarden.*}}           # Bitwarden template syntax
{{.*bitwardenFields.*}}     # Field accessors
{{.*bitwardenAttachment.*}} # Attachments
{{.*chezmoi\..*}}           # Chezmoi template syntax
{{.*onepassword.*}}         # 1Password vault
{{.*keepass.*}}             # KeePass vault
{{.*vault.*}}               # Generic vault references
age1[a-z0-9]{58}           # Age public keys (safe to commit)
```

**Stopwords (function names, not actual secrets):**
- `bitwarden`, `bitwardenFields`, `bitwardenAttachment`
- `onepassword`, `keepass`, `chezmoi`

**Safe paths (files that may contain example secrets):**
- `.gitleaks.toml` (config file itself)
- `.pre-commit-config.yaml` (hook definitions)
- `*.md`, `README.*` (documentation)

**What CANNOT be committed:**
- `.env` files (contain actual secrets)
- `*.pem`, `*.key`, `*.p12` (private keys)
- `id_rsa*`, `id_ed25519*` (SSH keys)
- `.npmrc`, `.pypirc`, `.netrc` (auth tokens)
- `serviceAccountKey.json`, `*-credentials.json` (cloud service keys)
- Inline secrets in any file (detected by regex patterns)

## Deployment Validation

### 1. Dry-Run Preview (chezmoi)

Before applying changes:

```bash
chezmoi diff              # Show pending changes as unified diff
chezmoi apply --dry-run   # Simulate apply without writing files
```

These commands let you review transformations before deployment.

### 2. Permission Verification (run_after_10-verify-permissions.sh.tmpl)

**When:** Runs after every `chezmoi apply`

**Purpose:** Enforce file permissions on sensitive files

**Mechanism:**

1. Defines sensitive file patterns with required permissions
2. Expands glob patterns and checks each file
3. Compares current vs required permissions
4. Fixes mismatches with `chmod`
5. Logs all fixes with timestamp to `~/.local/state/chezmoi/permission-fixes.log`

**Platform Support:**

- macOS: Uses `stat -f "%Lp"` (BSD stat)
- Linux: Uses `stat -c "%a"` (GNU stat)

**Enforced Permissions:**

| File Pattern | Permission | Purpose |
|--------------|------------|---------|
| `~/.ssh/id_*` | 600 | SSH private keys (read/write owner only) |
| `~/.ssh/config` | 600 | SSH config (read/write owner only) |
| `~/.ssh/authorized_keys` | 600 | Authorized keys (read/write owner only) |
| `~/.gnupg/private-keys-v1.d` | 700 | GPG keys directory (owner only) |
| `~/.config/age/key-*.txt` | 600 | Age encryption keys (owner only) |
| `~/.kube/config` | 600 | Kubernetes credentials |
| `~/.aws/credentials` | 600 | AWS credentials (secrets) |
| `~/.aws/config` | 644 | AWS config (public) |
| `~/.docker/config.json` | 600 | Docker credentials |
| `~/.config/gcloud/application_default_credentials.json` | 600 | GCP credentials |
| `~/.netrc` | 600 | FTP/remote login credentials |
| `~/.git-credentials` | 600 | Git stored credentials |
| `~/.gitconfig_local` | 600 | Local git config (may have tokens) |

**Verification Output:**

```
Fixed permissions: ~/.ssh/id_rsa (644 -> 600)
Permission verification complete - 1 file(s) fixed (see ~/.local/state/chezmoi/permission-fixes.log)
```

Log format:
```
[2026-02-15T14:23:45Z] Fixed: /Users/stephanlv_fanaka/.ssh/id_rsa (644 -> 600)
```

### 3. Drift Detection (chezmoi verify)

**Command:**
```bash
chezmoi verify    # Compare deployed files against source
```

**Purpose:** Detect manual changes to deployed files (drift from source)

**Use case:** Verify that `chezmoi apply` deployed correctly and no external changes were made.

**Exit codes:**
- 0: All files match source
- Non-zero: Drift detected (file modified after deployment)

## Smoke Testing

### ZSH Configuration Smoke Test

**Location:** `scripts/zsh-smoke-test` (ZSH script)

**Wrapper Task:** `private_dot_config/mise/tasks/dotfiles/executable_smoke-test` (Bash)

**Command:**
```bash
mise run dotfiles:smoke-test   # Via mise task runner
# or directly:
~/.local/share/chezmoi/scripts/zsh-smoke-test
```

**Exit codes:**
- 0: All checks passed ✓
- 1: One or more checks failed ✗

**Test Structure:**

```zsh
check() {
  local description="$1"
  local test_command="$2"
  if eval "$test_command"; then
    echo "[PASS] $description"
    ((PASS_COUNT++))
  else
    echo "[FAIL] $description"
    ((FAIL_COUNT++))
  fi
}
```

**Checks Performed:**

1. **oh-my-posh availability** - Prompt engine executable check
2. **Prompt configured** - `PROMPT` variable set
3. **Mise available** - Mise shims on PATH or command available
4. **Completion system** - Zsh completions initialised (`_comps` array)
5. **Atuin keybinding** - History search configured (bindkey check)
6. **Critical tools** - git, zoxide, fzf, bat, lsd commands available
7. **zsh-autosuggestions** - Plugin loaded (widget check with `zle -l`)
8. **zsh-syntax-highlighting** - Configured in sheldon (grep check)
9. **Startup monitoring** - `LAST_SHELL_STARTUP_MS` set (self-monitoring active)

**Example Output:**

```
ZSH Smoke Test
==============

[PASS] oh-my-posh command available
[PASS] Prompt is configured
[PASS] mise available (command or shims)
[PASS] Completion system initialised
[PASS] Atuin keybinding configured
[PASS] git available
[PASS] zoxide available
[PASS] fzf available
[PASS] bat available
[PASS] lsd available
[PASS] zsh-autosuggestions loaded
[PASS] zsh-syntax-highlighting configured in sheldon
[PASS] Startup monitoring active (LAST_SHELL_STARTUP_MS set)

Summary
=======
Passed: 13
Failed: 0

✓ All checks passed
```

### Performance Monitoring

**Startup Time Threshold:** 300ms

Configured in `.zshrc` via `LAST_SHELL_STARTUP_MS` environment variable:

```bash
if (( LAST_SHELL_STARTUP_MS > 300 )); then
  print -P "%F{yellow}Warning: shell startup ${LAST_SHELL_STARTUP_MS}ms (exceeds 300ms target)%f"
  print -P "%F{yellow}  Run: ZSH_PROFILE_STARTUP=1 zsh -i -c exit%f"
fi
```

This triggers if shell startup takes >300ms and suggests profiling with `ZSH_PROFILE_STARTUP=1`.

## Lifecycle Script Validation

### Run Script Validation Pattern

All run scripts use `set -eufo pipefail` (or `set -e`) for fail-fast error handling:

- `-e`: Exit on error (any non-zero exit code)
- `-u`: Error on undefined variables
- `-f`: Disable glob expansion
- `-o pipefail`: Catch errors in pipe chains

**Example from `run_onchange_after_02-cleanup-packages.sh.tmpl`:**

```bash
set -eufo pipefail
CLEANUP_LOG="${HOME}/.local/state/homebrew-cleanup.log"
mkdir -p "$(dirname "$CLEANUP_LOG")"
REMOVABLE=$(brew bundle cleanup --global 2>&1 || true)
if [ -z "$REMOVABLE" ]; then
  echo "==> No packages to clean up."
else
  brew bundle cleanup --global --force
fi
```

**Validation Points:**

1. Command existence: `if ! command -v brew &> /dev/null`
2. Exit code handling: `|| true` for non-fatal errors
3. Logging: Timestamped entries to `.local/state/chezmoi/*`
4. Platform gating: Early exit for unsupported OS

### Hash-Based Change Detection

Run scripts use content hashing to detect when to re-execute:

```bash
# .chezmoidata.yaml packages hash: {{ include ".chezmoidata.yaml" | sha256sum }}
```

When the hash of `.chezmoidata.yaml` changes, `run_onchange_*` scripts re-run automatically on next `chezmoi apply`.

## Ignore Patterns Validation

**File:** `.chezmoiignore`

**Validation:** 11 sections with OS-conditional logic prevent unintended deployments

- **Section 1:** Dotbot infrastructure (never deploy)
- **Section 2:** Repo metadata (CLAUDE.md, .git/, .github/)
- **Section 3:** Brewfile (managed separately)
- **Section 4:** macOS system scripts (.macos)
- **Section 5:** OS-specific configs (i3, aerospace)
- **Section 6:** Already-managed configs (reference section)
- **Section 7:** Encryption keys (outside chezmoi scope)
- **Section 8:** Terminal cache (auto-generated files)
- **Section 9:** Claude Code local state (non-sync)
- **Section 10:** Deprecated configs (marked for removal)
- **Section 11:** Development/temp files

**Platform Conditionals in .chezmoiignore:**

```
{{- if ne .chezmoi.os "darwin" }}
# macOS-only configs — ignore on Linux
.config/aerospace/**
Library/**
{{- end }}
```

## Test Coverage Gaps

**Untested Areas:**

1. **Template Rendering** - Go template syntax correctness not validated until `chezmoi apply`
   - Risk: Malformed templates cause deployment failures
   - Current: Only caught when running chezmoi commands

2. **Shell Function Behavior** - Functions in `dot_zsh.d/` not unit tested
   - Risk: Breaking changes in utility functions like `clone()`, `run-mr-code-reviewer()`
   - Current: Only smoke-tested at runtime

3. **Conditional Logic** - Machine-type and OS-specific branches not exhaustively tested
   - Risk: Client-only configs deployed to personal machines
   - Current: Manual `chezmoi diff --dry-run` verification

4. **Package Dependency Resolution** - Brewfile doesn't validate tap dependency order
   - Risk: Package installation order issues on clean systems
   - Current: Caught only during actual Homebrew install

5. **Configuration Secrets** - No validation that all vault references resolve
   - Risk: Bitwarden/1Password template variables fail during `chezmoi apply`
   - Current: Fails during apply, not pre-commit

6. **Path Expansion** - Glob patterns in `run_after_10-verify-permissions.sh.tmpl` not pre-validated
   - Risk: Permission patterns fail to match files
   - Current: Silently skips non-existent files (by design)

7. **Cross-Module Dependencies** - No validation of inter-module loading order in sheldon
   - Risk: Plugin load order conflicts cause shell errors
   - Current: Caught by smoke test at runtime

## Recommended Quality Checkpoints

**Pre-deployment:**
1. Run `chezmoi diff` to review template rendering
2. Run `chezmoi apply --dry-run` to verify no errors
3. Run `pre-commit run --all-files` to check secrets and syntax

**Post-deployment:**
1. Verify with `chezmoi verify` for drift
2. Run smoke test: `mise run dotfiles:smoke-test`
3. Check permission log: `cat ~/.local/state/chezmoi/permission-fixes.log`

**Ongoing:**
1. Monitor shell startup time (watch `LAST_SHELL_STARTUP_MS`)
2. Review permission fixes log after each `chezmoi apply`
3. Run `chezmoi doctor` to diagnose configuration issues

---

*Testing analysis: 2026-02-15*
