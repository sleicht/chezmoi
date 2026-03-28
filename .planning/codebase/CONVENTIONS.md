# Coding Conventions

**Analysis Date:** 2026-02-15

## File Naming Conventions

**Chezmoi Prefixes:**

Chezmoi source files use standardised prefixes that transform when deployed via `chezmoi apply`:

- `dot_` prefix: Becomes `.` → `dot_zshrc` → `~/.zshrc`
- `private_dot_` prefix: Becomes `.` with restricted permissions (700) → `private_dot_config/` → `~/.config/`
- `executable_` prefix: Sets file as executable (+x) → `executable_pre-commit` → executable file
- `.tmpl` suffix: Marks file for Go template processing → `path.zsh.tmpl`
- `run_once_before_` prefix: Script runs once at init, before deployment phase → `run_once_before_install-homebrew.sh.tmpl`
- `run_onchange_` prefix: Script runs when content hash changes → `run_onchange_after_01-install-packages.sh.tmpl`
- `run_after_` prefix: Script runs on every `chezmoi apply` → `run_after_10-verify-permissions.sh.tmpl`

Run scripts follow numeric ordering (01, 02, 03...) to establish execution sequence across lifecycle phases:
1. Bootstrap (00-09): Homebrew install, initial setup
2. Install (01-09): Package management
3. Cleanup (02-XX): Unused package removal
4. Verification (10-XX): Permission checks, state validation

**File Organization:**
- Shell configuration modules: `dot_zsh.d/*.zsh` (modular ZSH config with defer-loading)
- Configuration data: `.chezmoidata.yaml` (~6300 lines, static data referenced by all templates)
- Lifecycle scripts: `run_*_*.sh.tmpl` (numbered for ordering)
- Private/sensitive: `private_dot_*` (SSH keys, credentials, age key bootstrap)
- Repository metadata: Top level (CLAUDE.md, .gitleaks.toml, .pre-commit-config.yaml)

## Template Conventions

**Go Template Syntax:**

All template files use Go template syntax with chezmoi-specific functions:

- Machine type conditionals: `{{- if eq .machine_type "client" }}...{{- end }}`
- OS conditionals: `{{- if ne .chezmoi.os "darwin" }}...{{- end }}`
- Data includes: `{{ include ".chezmoidata.yaml" | sha256sum }}`
- Secret vault integration: `{{bitwarden "field"}}`, `{{onepassword "field"}}`, `{{keepass "field"}}`
- Path references: `{{ .chezmoi.homeDir }}`, `{{ .chezmoi.os }}`

Conditionals use negative checks to simplify logic:
- `{{- if ne .chezmoi.os "darwin" }} exit 0 {{- end }}` (skip on non-macOS)

Data variables follow scope patterns:
- `.machine_type`: `"client"` (work) or `"personal"`
- `.personal_email`, `.work_email`: Set during `chezmoi init`
- `.chezmoi.os`: `"darwin"` or `"linux"`

## Shell Script Conventions

**Shebang & Options:**

- Bash scripts: `#!/bin/bash`
- ZSH scripts: `#!/usr/bin/env zsh`
- Error handling: All run scripts use `set -e` or `set -eufo pipefail` (fail fast, exit on error)
  - `set -e`: Exit on any error
  - `set -u`: Error on undefined variables
  - `set -f`: Disable glob expansion (optional, for pipefail contexts)
  - `set -o pipefail`: Catch errors in pipe chains (e.g., `cmd | transform`)

**Variable Naming:**

- Shell variables: UPPERCASE with underscores for multi-word → `LOG_DIR`, `CLEANUP_LOG`, `SENSITIVE_FILES`
- Local variables in functions: lowercase with underscores → `local current_perm`, `local file`
- Loop counters: Simple names → `((fixes_made++))`, `((PASS_COUNT++))`

**Error Handling Patterns:**

- Permission checking: Explicit `-e` file test before operations
  ```bash
  if [[ ! -e "$file" ]]; then
      continue
  fi
  ```

- Command existence: Hash check with fallback
  ```bash
  if ! command -v brew &> /dev/null; then
      # install brew
  fi
  ```

- Error suppression (when intentional): Redirect to `/dev/null`
  ```bash
  brew list "$pkg" &>/dev/null   # Suppress both stdout and stderr
  brew uninstall "$pkg" || true  # Continue on error
  ```

- Logging: Timestamped entries to dedicated log files
  ```bash
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$timestamp] Fixed: $file ($current_perm -> $required_perm)" >> "$LOG_FILE"
  ```

**Function Design:**

Functions follow these patterns:

- Short header comment explaining purpose
- Parameter validation with early return
- Return codes: 0 for success, 1 for error, 137 for usage errors
- Quoting all variables to handle spaces: `"$file"`, `"$@"`
- Platform-specific branches handled early (macOS vs Linux detection)

Example from `dot_zsh.d/functions.zsh`:
```bash
mc () {
  if [ $# -ne 1 ]; then
    echo 'usage: mc <dir-name>'
    return 137  # Usage error code
  fi
  local dir_name="$1"
  mkdir -p "$dir_name" && cd "$dir_name"
}
```

## Comments & Documentation

**Comment Style:**

- Line comments (shell): `# Description` with space after hash
- Section headers: Repeated symbols for visual grouping
  ```bash
  # === Section Name ===
  # Descriptive paragraph
  ```

- Inline comments: Explain "why", not "what"
  ```bash
  # Skip on non-macOS systems (mise completions are ZSH-specific)
  if [[ "$OSTYPE" == darwin* ]]; then
  ```

- Condition comments: Explain non-obvious logic
  ```bash
  # python@3.x packages are kept as they're build dependencies
  # They use versioned paths (/opt/homebrew/opt/python@3.12/bin)
  # and don't conflict with mise's python management
  ```

**File Headers:**

All executable/template files start with:
```bash
#!/bin/bash                              # or #!/usr/bin/env zsh
# Brief description
# Longer context if needed (when runs, what it does)
```

Runtime scripts include:
```bash
# .chezmoidata.yaml packages hash: {{ include ".chezmoidata.yaml" | sha256sum }}
```
This triggers `run_onchange_` re-execution when package list updates.

**Zsh Inline Comments:**

Comments in shell functions use descriptive style:
```zsh
# Cleans py[cod] and cache dirs in the current tree:
# `tre` is a shorthand for `tree` with hidden files and color enabled
```

## Git Commit Conventions

**Format:** Jira ticket prefix + Conventional Commits

- Pattern: `<JIRA-TICKET>: <type>(scope): <description>`
- Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `perf`, `test`
- Rules:
  - Imperative present tense: "add" not "added"
  - No capitalised first letter
  - No trailing period
  - Scope optional: `fix(permissions): chmod sensitive files after apply`
  - Breaking changes marked with `!`: `feat!: ...`

**Examples from repo:**
- `chore: move planning artifacts from dotfiles-zsh`
- `docs: update README with mise task runner workflow`
- `feat(25): optional ticket and AI mode for git:pr task`
- `fix(25): add cleanup and pr tasks to chezmoi source`
- `perf(25): use haiku model for git task AI mode`

**Branching:**

Only create feature branches when needed:
- Pattern: `feature/<JIRA-TICKET>-...`
- Main branches (no branching): `main`, `master`, `develop`

**Commit Body:**

- Max 10 bullet points
- Focus on "why" not "what"
- Detailed reasoning for non-obvious changes

## Configuration & Data Organization

**Static Data (.chezmoidata.yaml):**

Package lists organised by scope:
- `darwin.common_*`: Packages needed on all macOS machines
- `darwin.client_*`: Work machine only packages
- `darwin.personal_*`: Personal machine only packages

Data references in templates: `{{ .packages.darwin.common_brews }}`

**Permission Verification:**

Sensitive file permissions enforced post-apply via `run_after_10-verify-permissions.sh.tmpl`:
- SSH keys: 600 (`~/.ssh/id_*`, `~/.ssh/config`)
- SSH public: 644 (`~/.ssh/authorized_keys`)
- GPG keys: 700 (`~/.gnupg/private-keys-v1.d`)
- Age keys: 600 (`~/.config/age/key-*.txt`)
- Cloud credentials: 600 (AWS, GCP, Docker, kube configs)
- Public configs: 644 (`~/.aws/config`)

Violations automatically logged to `~/.local/state/chezmoi/permission-fixes.log` with timestamp, file path, and permission change.

**Encryption:**

Age encryption (not chezmoi-managed) for sensitive files:
- Public key committed: `age1...` (58 chars, safe)
- Private key stored outside chezmoi: `~/.config/age/key-{machine_type}.txt` (never deployed via `chezmoi apply`)

## Code Style

**Shell Spacing:**

- Function definitions: One blank line before
- Conditionals: Space inside `[[ ... ]]`
- Variable assignment: No spaces around `=`
- Arrays: `ARRAY=("item1" "item2")`

**Quoting Rules:**

- Always quote variables: `"$var"` not `$var`
- Use double quotes for expansion: `"$HOME/.config"`
- Use single quotes for literals: `'text'`
- In arrays with variables: `( "${ARRAY[@]}" )` expands

**Platform Conditionals:**

Always detect and branch early:
```bash
if [[ "$OSTYPE" == darwin* ]]; then
    stat -f "%Lp" "$file"      # macOS
else
    stat -c "%a" "$file"       # GNU Linux
fi
```

---

*Convention analysis: 2026-02-15*
