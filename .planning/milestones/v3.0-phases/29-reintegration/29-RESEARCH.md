# Phase 29: Reintegration - Research

**Researched:** 2026-02-15
**Domain:** chezmoi dotfile reintegration workflows
**Confidence:** HIGH

## Summary

Phase 29 involves evaluating and reintegrating local customisations captured during the migration audit (Phase 26) and conflict resolution (Phase 28) back into the chezmoi-managed dotfiles repository. This is fundamentally about making informed triage decisions: what belongs in version-controlled, templated chezmoi source; what should remain local and unmanaged; and what can be safely discarded.

The domain is well-supported by chezmoi's command set and follows established dotfile management patterns. The key challenges are human decision-making (evaluating value of local customisations) and avoiding common pitfalls (breaking templates, losing secrets, overwriting the wrong file). Chezmoi provides explicit commands for each workflow: `chezmoi add` for ingesting new files, `chezmoi re-add` for updating existing, `chezmoi merge` for three-way conflict resolution, and `chezmoi diff` for inspection.

**Primary recommendation:** Use a structured triage workflow with clear decision criteria for each category (scripts, env vars, config edits). Leverage chezmoi's built-in commands for safe reintegration, template machine-specific content with `.machine_type` conditionals, and establish a local override pattern for truly ephemeral or secret values.

## Standard Stack

### Core Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `chezmoi add [file]` | Add new file to chezmoi management | Ingesting custom scripts or untracked configs |
| `chezmoi re-add [file]` | Re-add modified file, preserving encryption | Updating an already-managed file after manual edits |
| `chezmoi diff [file]` | Show differences between source and target | Preview changes before apply, inspect conflicts |
| `chezmoi merge [file]` | Three-way merge (source, target, destination) | Resolving complex conflicts interactively |
| `chezmoi edit [file]` | Edit source file in chezmoi repo | Making manual changes to source |
| `chezmoi source-path [file]` | Print path to source file | Finding the chezmoi source for a target file |
| `chezmoi managed` | List all managed files | Verifying what's under chezmoi control |
| `chezmoi unmanaged [path]` | List files NOT managed by chezmoi | Discovering files that could be added |
| `chezmoi forget [file]` | Remove from management, keep in destination | Unmanaging a file without deleting it |
| `chezmoi execute-template` | Test/debug Go templates | Validating template syntax before apply |

### Supporting Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `diff` or `delta` | Compare local edits to deployed files | Manual inspection of saved edits |
| `vimdiff` | Default merge tool | Three-way merge if not configured otherwise |
| Git | Version control chezmoi source | Commit reintegrated changes |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `chezmoi add` | Manual copy to `~/.local/share/chezmoi/` | More control but error-prone (wrong naming, missing attributes) |
| `chezmoi merge` | Manual side-by-side edit | Works without merge tool config, but harder for complex merges |
| Template conditionals | Separate machine-specific files | Cleaner when differences are large, but more files to manage |
| Local override files | Template ALL variables | Override files better for secrets/ephemeral values that shouldn't be in git |

**Installation:**

No additional packages required. All commands are built into chezmoi. Optional: configure a merge tool for `chezmoi merge`:

```toml
# ~/.config/chezmoi/chezmoi.toml
[merge]
command = "nvim"
args = ["-d", "{{ .Destination }}", "{{ .Source }}", "{{ .Target }}"]
```

## Architecture Patterns

### Recommended Triage Workflow

```
For each local customisation:
1. Identify category (script, env var, config edit)
2. Evaluate value (still needed? machine-specific? contains secrets?)
3. Choose destination:
   - chezmoi source (version-controlled, templated if machine-specific)
   - local override file (ephemeral, secrets, rapid changes)
   - discard (obsolete, superseded)
4. Apply using appropriate chezmoi command
5. Verify with chezmoi diff and test
```

### Pattern 1: Adding Custom Scripts to Chezmoi

**What:** Use `chezmoi add` to bring untracked scripts under management. If script is machine-specific, add to `.chezmoiignore` for other machines.

**When to use:** Script is valuable across machines OR should be version-controlled, AND is currently in `~/bin`, `~/.bin`, or `~/.local/bin`.

**Example:**

```bash
# Source: chezmoi official docs - https://www.chezmoi.io/reference/commands/add/
# Add an executable script (chezmoi auto-detects +x and adds executable_ prefix)
chezmoi add ~/bin/useful-script

# Verify it's managed with correct attributes
chezmoi managed | grep useful-script
ls -la $(chezmoi source-path ~/bin/useful-script)
# Should show: executable_bin/useful-script

# If script is client-only, add to .chezmoiignore for personal machines:
chezmoi edit ~/.chezmoiignore
```

In `.chezmoiignore`:
```
{{- if ne .machine_type "client" }}
bin/useful-script
{{- end }}
```

**Edge case:** If script has secrets embedded, extract to Bitwarden and convert to template:
```bash
# Add as template
chezmoi add --template ~/bin/script-with-secret
# Edit to replace secret with Bitwarden lookup
chezmoi edit ~/bin/script-with-secret
```

### Pattern 2: Templating Machine-Specific Environment Variables

**What:** Add client-specific env vars to chezmoi source with `.machine_type` conditionals, or create a new client-only module excluded via `.chezmoiignore` on personal machines.

**When to use:** Env var is client-specific, stable (not frequently changing), and does NOT contain secrets.

**Example:**

```bash
# Source: existing repo pattern from dot_zshrc.tmpl lines 26-31
# Option A: Add to existing module by converting to template
cd ~/.local/share/chezmoi
git mv dot_zsh.d/variables.zsh dot_zsh.d/variables.zsh.tmpl

# Edit the template
chezmoi edit ~/.zsh.d/variables.zsh
```

Add at bottom of `variables.zsh.tmpl`:
```zsh
{{- if eq .machine_type "client" }}
# === Client-specific variables ===
export COMPANY_PROXY="http://proxy.company.com:8080"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-11.jdk/Contents/Home"
{{- end }}
```

```bash
# Apply and test
chezmoi apply ~/.zsh.d/variables.zsh
exec zsh
echo $COMPANY_PROXY  # Should print the value
```

**Option B:** Create a new client-only module (preferred for many variables):
```bash
# Create client-vars.zsh in target location
cat > ~/.zsh.d/client-vars.zsh << 'EOF'
#!/usr/bin/env zsh
# Client-machine-only variables
export VAR1="value"
export VAR2="value"
EOF

# Add to chezmoi
chezmoi add ~/.zsh.d/client-vars.zsh

# Exclude from personal machines
chezmoi edit ~/.chezmoiignore
```

In `.chezmoiignore`:
```
{{- if ne .machine_type "client" }}
.zsh.d/client-vars.zsh
{{- end }}
```

### Pattern 3: Local Override File for Secrets and Ephemeral Values

**What:** Create an unmanaged local override file (e.g., `~/.zsh.d.local`) sourced by `.zshrc` but NOT added to chezmoi. Only the source line is managed.

**When to use:** Env var contains secrets, changes frequently, or is truly ephemeral (temp paths, session tokens).

**Example:**

```bash
# Source: common dotfile pattern from thoughtbot/dotfiles and multiple Stack Overflow discussions
# Create the local override file (NOT managed by chezmoi)
cat > ~/.zsh.d.local << 'EOF'
# Local overrides -- NOT managed by chezmoi
# This file is intentionally outside chezmoi management
# Add machine-specific variables, secrets, and temporary overrides here

export COMPANY_API_TOKEN="secret-value-here"
export LOCAL_PROJECT_PATH="/Users/me/work/project"
EOF

# Add source line to .zshrc template
chezmoi edit ~/.zshrc
```

Add before the startup monitoring section:
```zsh
# === Local overrides (not managed by chezmoi) ===
[[ -f "$HOME/.zsh.d.local" ]] && source "$HOME/.zsh.d.local"
```

```bash
# Apply and verify
chezmoi apply ~/.zshrc
exec zsh
echo $COMPANY_API_TOKEN  # Should print the secret value

# Confirm .zsh.d.local is NOT managed
chezmoi managed | grep -q '.zsh.d.local' && echo "ERROR: should not be managed" || echo "OK: not managed"
```

**Critical:** Never run `chezmoi add ~/.zsh.d.local` — it should remain unmanaged. If accidentally added, run `chezmoi forget ~/.zsh.d.local`.

### Pattern 4: Merging Drifted Config Edits

**What:** Use `chezmoi merge` for three-way conflict resolution, or manually edit the chezmoi source for simple changes.

**When to use:** Local version of a managed file has valuable edits not yet in chezmoi source (saved to `~/migration-audit/local-edits/` during Phase 28).

**Example:**

```bash
# Source: chezmoi official docs - https://www.chezmoi.io/user-guide/tools/merge/
# Approach A: Manual edit for simple changes
chezmoi diff ~/.gitconfig  # See what differs
chezmoi edit ~/.gitconfig  # Edit source to add valuable lines
chezmoi apply ~/.gitconfig  # Deploy updated source

# Approach B: Three-way merge for complex changes
# Temporarily restore the local edit to the target location
cp ~/migration-audit/local-edits/gitconfig ~/.gitconfig
# Launch merge tool (requires merge.command configured in chezmoi.toml)
chezmoi merge ~/.gitconfig
# Resolve conflicts in merge tool, save to source
# Apply the merged result
chezmoi apply ~/.gitconfig

# Approach C: Overwrite source when local is definitively better
cp ~/migration-audit/local-edits/gitconfig $(chezmoi source-path ~/.gitconfig)
chezmoi diff ~/.gitconfig  # Verify no unexpected changes
chezmoi apply ~/.gitconfig
```

**Verification:**
```bash
# After any merge, verify sync
chezmoi diff --exclude=scripts
# Expected: empty output
```

### Pattern 5: Using `chezmoi unmanaged` to Discover Candidates

**What:** Run `chezmoi unmanaged` to list files in the home directory that are NOT managed by chezmoi, identifying candidates for reintegration.

**When to use:** After migration, to find files that were never in the old dotfiles repo and weren't captured by the manual audit.

**Example:**

```bash
# Source: chezmoi official docs - https://www.chezmoi.io/reference/commands/unmanaged/
# Scan common config directories for unmanaged files
chezmoi unmanaged ~/.config ~/.zsh.d ~/bin ~/.local/bin

# Use tree format for better visibility
chezmoi unmanaged --tree ~/.config

# Filter to specific types
chezmoi unmanaged --include=files ~/.config
```

Review output and decide: add to chezmoi, keep local, or discard.

### Anti-Patterns to Avoid

- **Re-adding templates with `chezmoi add`:** Running `chezmoi add` on a file that's already a template will overwrite the template with a static file. Use `chezmoi re-add` instead, but note: "re-add doesn't work with templates" (from official FAQ). For templates, edit the source directly with `chezmoi edit`.

- **Adding secrets directly to chezmoi source:** Never add files containing raw secrets (API tokens, passwords) to chezmoi source. Use Bitwarden template lookups or keep in local override files.

- **Breaking template syntax:** When converting a file to `.tmpl`, forgetting to close conditionals (`{{ end }}`) or using wrong variable names breaks rendering. Always verify with `chezmoi execute-template < $(chezmoi source-path ~/.file)`.

- **Using `chezmoi add --autotemplate` blindly:** The autotemplate feature uses a greedy substitution algorithm that may create unintended template references. Always review the generated template carefully.

- **Ignoring the wrong path:** `.chezmoiignore` matches against target paths (e.g., `.zsh.d/file.zsh`), NOT source paths (e.g., `dot_zsh.d/file.zsh`). Use target notation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File difference inspection | Manual `diff` between source and target | `chezmoi diff [file]` | Handles templates correctly (renders before diffing), respects encryption, built-in pager |
| Three-way merge | Copy files around and use `diff3` manually | `chezmoi merge [file]` | Understands source/target/destination states, integrates with configured merge tool |
| Finding the source file | Navigate `~/.local/share/chezmoi/` manually | `chezmoi source-path [file]` | Translates target path to source path automatically (handles prefixes, suffixes) |
| Templating machine-specific content | Shell if-statements checking hostname | Go templates with `.machine_type` | Centralized variable in `.chezmoi.yaml.tmpl`, consistent across all files, works in any file type (not just shell scripts) |
| Local override pattern | Custom logic in each file | Standardized `.local` suffix pattern | Convention established across dotfile community, clear signal of "not in version control" |

**Key insight:** Chezmoi's command set is designed for safe file reintegration workflows. The biggest risk is human error (wrong file, broken template), not tool limitation. Use chezmoi commands rather than low-level file operations to leverage safety checks and automatic attribute handling.

## Common Pitfalls

### Pitfall 1: Re-adding Templates Destroys Template Syntax

**What goes wrong:** User runs `chezmoi add ~/.zshrc` on a file that's already managed as `dot_zshrc.tmpl`. Chezmoi replaces the source template with the rendered output (static file), losing all template logic.

**Why it happens:** `chezmoi add` is designed for ingesting new files or replacing source with current target. It doesn't preserve template syntax from the source; it takes the target literally.

**How to avoid:**
- For already-managed files, use `chezmoi re-add` to update from target (but note: "re-add doesn't work with templates")
- For templates, NEVER re-add from target — always edit the source directly with `chezmoi edit`
- Check if file is managed before adding: `chezmoi managed | grep -q '.zshrc' && echo "Already managed"`

**Warning signs:**
- After `chezmoi add`, `git diff` in `~/.local/share/chezmoi/` shows template syntax removed
- File changed from `.tmpl` suffix to no suffix in source
- Machine-specific conditionals disappeared from source

**Recovery:** `git checkout` the source file if caught immediately, or restore from git history.

### Pitfall 2: Secrets Leaked into Git History

**What goes wrong:** User adds a file containing secrets (API tokens, passwords) to chezmoi source without templating or encrypting it. The secret is committed to git and pushed to remote.

**Why it happens:** Workflow rushes reintegration without inspecting file contents first. Assumed file was "just config" without checking for sensitive values.

**How to avoid:**
- ALWAYS inspect files before adding: `cat ~/file | grep -i 'token\|password\|secret\|key'`
- Use Bitwarden template lookups for secrets: `{{ (bitwarden "item-id").login.password }}`
- OR keep files with secrets in local override (unmanaged)
- OR use `chezmoi add --encrypt` for entire-file encryption (requires age key)
- Check git diff before committing: `cd ~/.local/share/chezmoi && git diff`

**Warning signs:**
- File contains string literals that look like tokens/passwords
- Pre-commit hook (gitleaks) alerts on secret patterns
- File path matches common secret patterns (`.env`, `credentials.json`)

**Recovery:** Immediately remove from history with `git filter-branch` or BFG Repo-Cleaner, rotate the secret.

### Pitfall 3: Template Syntax Errors Break Apply

**What goes wrong:** After manually editing a `.tmpl` file or converting a file to template, running `chezmoi apply` fails with Go template syntax errors (unclosed blocks, undefined variables, wrong function names).

**Why it happens:** Go template syntax is strict and errors are not obvious until runtime. Common mistakes: forgot `{{ end }}`, typo in variable name (`.machine_type` vs `.machinetype`), wrong function syntax.

**How to avoid:**
- Test templates before applying: `chezmoi execute-template < $(chezmoi source-path ~/.file)`
- Use `chezmoi diff` to preview rendered output before apply
- Follow existing template patterns from the repo (see `dot_zshrc.tmpl`, `dot_profile.tmpl`)
- Use consistent indentation and comments for readability

**Warning signs:**
- `chezmoi apply` errors with "template: ...:X: unexpected ..." or "undefined variable"
- `chezmoi diff` produces no output (template failed to render)
- File doesn't appear in `chezmoi managed` after adding as template

**Recovery:**
- Check syntax with `chezmoi execute-template`
- Review recent edits in chezmoi source: `cd ~/.local/share/chezmoi && git diff`
- Restore working version from git history and retry carefully

### Pitfall 4: Wrong Decision on Add vs Keep Local

**What goes wrong:** User adds a machine-specific script or config to chezmoi without templating it, then it deploys to personal machine where it's useless or breaks things. OR user keeps a valuable script local, then loses it when machine dies (no backup).

**Why it happens:** Unclear decision criteria. Rushes triage without thinking through implications.

**How to avoid:**
- Use clear triage criteria:
  - **Add to chezmoi:** Valuable across machines OR needed on multiple machines OR worth version-controlling
  - **Add with template/ignore:** Machine-specific but still valuable (use `.chezmoiignore` to exclude from other machines)
  - **Keep local:** Truly ephemeral, changes daily, OR contains secrets that shouldn't be templated
  - **Discard:** Obsolete, superseded, or no longer needed
- When in doubt, add to chezmoi with `.chezmoiignore` — easier to exclude later than to lose it
- Document local-only decisions in `~/migration-audit/local-scripts-inventory.txt` for reference

**Warning signs:**
- After deploying to another machine, find useless or broken scripts in `~/bin`
- Realize a valuable local script is gone after machine refresh (no version control)

**Prevention:** Review Phase 26 audit files carefully. Cross-reference with chezmoi-managed bins from personal Mac.

### Pitfall 5: Overwriting Valuable Local Edits During Merge

**What goes wrong:** During manual merge or when using `chezmoi apply --force`, user accidentally overwrites the valuable local version with the chezmoi source version, losing work.

**Why it happens:** Unclear which direction the merge is going. Confusion between "source overwrites target" (apply) and "target overwrites source" (re-add). Rushing without backing up first.

**How to avoid:**
- ALWAYS save local edits BEFORE merging: `cp ~/.file ~/migration-audit/local-edits/file`
- Use `chezmoi diff ~/.file` to understand what would change BEFORE applying
- For complex merges, use `chezmoi merge` with a configured merge tool (interactive, safer)
- Test after merge: verify the result has the valuable edits you wanted to keep

**Warning signs:**
- After apply, realize a setting you manually configured is gone
- File reverted to "default" behaviour you had customized

**Recovery:** Restore from `~/migration-audit/local-edits/` backup if taken. Otherwise, restore from system backup or recreate from memory.

## Code Examples

Verified patterns from official sources:

### Discovering Unmanaged Files

```bash
# Source: https://www.chezmoi.io/reference/commands/unmanaged/
# List all unmanaged files in common config directories
chezmoi unmanaged ~/.config ~/.zsh.d ~/bin ~/.local/bin ~/.ssh

# Use tree view for better organization
chezmoi unmanaged --tree ~/.config

# Filter to files only (exclude directories)
chezmoi unmanaged --include=files ~/.config
```

### Adding Files with Attributes

```bash
# Source: https://www.chezmoi.io/reference/commands/add/
# Add an executable script (auto-detects +x)
chezmoi add ~/bin/my-script

# Add as template (enables Go template syntax)
chezmoi add --template ~/.config/app/config

# Add with autotemplate (auto-substitute known variables)
chezmoi add --autotemplate ~/.gitconfig

# Add and encrypt (requires age encryption configured)
chezmoi add --encrypt ~/.ssh/id_rsa

# Force overwrite existing source template
chezmoi add --force ~/.zshrc
```

### Template Conditional Syntax

```go
{{- /* Source: existing repo pattern from dot_zshrc.tmpl */ -}}
{{- if eq .machine_type "client" }}
# === Client-machine-only configuration ===
export COMPANY_VAR="value"
{{- end }}

{{- if eq .chezmoi.os "darwin" }}
# === macOS-specific configuration ===
export HOMEBREW_PREFIX="/opt/homebrew"
{{- end }}

{{- if and (eq .chezmoi.os "darwin") (eq .machine_type "client") }}
# === macOS AND client machine ===
# Combine multiple conditions
{{- end }}

{{- if ne .machine_type "client" }}
# === Personal machines only (NOT client) ===
{{- end }}
```

### .chezmoiignore Pattern for Machine-Specific Files

```
# Source: https://www.chezmoi.io/reference/special-files/chezmoiignore/
# Exclude client-specific files from personal machines
{{- if ne .machine_type "client" }}
bin/company-vpn-script
.zsh.d/client-vars.zsh
.config/work-app/
{{- end }}

# Exclude personal files from client machines
{{- if ne .machine_type "personal" }}
.config/personal-app/
bin/home-backup-script
{{- end }}

# OS-specific exclusions
{{- if ne .chezmoi.os "darwin" }}
.config/macos-specific/
{{- end }}
```

### Debugging Template Syntax

```bash
# Source: https://www.chezmoi.io/user-guide/templating/
# Test template rendering without applying
chezmoi execute-template < $(chezmoi source-path ~/.zshrc)

# Test inline template string
echo '{{ .machine_type }}' | chezmoi execute-template
# Outputs: client

# Preview rendered output of a specific file
chezmoi cat ~/.zshrc

# Show diff with custom diff tool
chezmoi diff --exclude=scripts
```

### Merge Workflow for Conflicts

```bash
# Source: https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/
# Save current local version before merge
cp ~/.config/app/config ~/migration-audit/local-edits/app-config

# Approach 1: Interactive three-way merge (requires merge tool configured)
chezmoi merge ~/.config/app/config

# Approach 2: Manual side-by-side edit
chezmoi edit ~/.config/app/config
# In another pane: cat ~/migration-audit/local-edits/app-config
# Copy valuable lines from local edit to source, save, then apply
chezmoi apply ~/.config/app/config

# Approach 3: Replace source entirely with local version
cp ~/migration-audit/local-edits/app-config $(chezmoi source-path ~/.config/app/config)
chezmoi diff ~/.config/app/config  # Verify
chezmoi apply ~/.config/app/config
```

### Verification Workflow After Reintegration

```bash
# Source: Phase 28 and Phase 29 runbooks
# Verify chezmoi is fully in sync (no differences)
chezmoi diff --exclude=scripts
# Expected: empty output

# Verify all intended files are managed
chezmoi managed | wc -l
# Compare to baseline count from Phase 27

# Verify machine-specific files deployed correctly
chezmoi managed | grep -E 'client|work'

# Test shell loads without errors
exec zsh

# Verify critical variables are set
echo "Machine type: $MACHINE_TYPE"
env | grep -i 'company\|work\|client'
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `chezmoi add` for templates | `chezmoi edit` for templates | Always been best practice | Prevents destroying template syntax; `add` overwrites templates with rendered output |
| Manual `diff` for inspection | `chezmoi diff` | chezmoi v1.0+ | Renders templates before diffing, handles encryption, respects ignore patterns |
| `--autotemplate` without review | `--autotemplate` then inspect output | Community best practice ~2020 | Greedy algorithm can create unintended substitutions; manual review essential |
| Single `.zshrc` with hostname checks | Modular `.zsh.d/*.zsh` with templates | Modern dotfile pattern ~2019 | Better organization, easier to manage machine-specific vs shared configs |
| Store secrets in dotfiles | Bitwarden/1Password integration + templates | chezmoi v2.0+ (2021) | Keeps secrets out of git history entirely |

**Deprecated/outdated:**

- **`chezmoi source` command:** Replaced by `chezmoi cd` for navigating to source directory (renamed in v2.0)
- **`.chezmoiremove` for unmanaging files:** Use `chezmoi forget` instead (clearer naming, introduced v2.0)
- **Storing age keys in chezmoi source:** Age keys should NEVER be in the source; keep in `~/.config/age/` outside chezmoi management (always been best practice, but early tutorials got this wrong)

## Open Questions

1. **What if the user has NO merge tool configured for `chezmoi merge`?**
   - What we know: `chezmoi merge` defaults to `vimdiff` if no `merge.command` is set in config. Many users may not have vimdiff skills.
   - What's unclear: Should the runbook check for merge tool config and warn if not set? Or just emphasize manual edit approach (Approach A)?
   - Recommendation: Runbook should provide BOTH approaches (merge and manual edit) with equal weight. Note that merge requires config, manual edit always works.

2. **How to handle files that were templated in old dotfiles-zsh but not yet templated in chezmoi?**
   - What we know: Old dotfiles-zsh may have used different templating (Jinja2, bash conditionals). Chezmoi uses Go templates.
   - What's unclear: Conversion strategy — rewrite from scratch or translate old template syntax?
   - Recommendation: Runbook should note this scenario in Procedure 3 troubleshooting. If old file had templating, user must manually translate to Go template syntax. Cannot blindly copy.

3. **Should local override files be documented in chezmoi source (README) or kept entirely outside?**
   - What we know: Convention is to add a source line in `.zshrc` but NOT add the `.local` file itself to chezmoi.
   - What's unclear: Best practice for documenting what SHOULD be in `.local` file for future reference.
   - Recommendation: Create a template stub in chezmoi (e.g., `dot_zsh.d.local.example`) that documents expected variables but is excluded via `.chezmoiignore`. User copies to `.local` and customizes.

## Sources

### Primary (HIGH confidence)

- [chezmoi command overview](https://www.chezmoi.io/user-guide/command-overview/) - Core workflow (add, diff, merge, status)
- [chezmoi add reference](https://www.chezmoi.io/reference/commands/add/) - Flags, attribute detection, template/encrypt options
- [chezmoi re-add reference](https://www.chezmoi.io/reference/commands/re-add/) - Re-adding modified files, limitations with templates
- [chezmoi diff reference](https://www.chezmoi.io/reference/commands/diff/) - Diff command, custom tools, preview workflow
- [chezmoi merge tool config](https://www.chezmoi.io/user-guide/tools/merge/) - Three-way merge, tool configuration, template variables
- [chezmoi templating guide](https://www.chezmoi.io/user-guide/templating/) - Machine-specific conditionals, `.chezmoidata.yaml`, template testing
- [chezmoi template variables](https://www.chezmoi.io/reference/templates/variables/) - Built-in variables (`.chezmoi.os`, `.chezmoi.hostname`, custom data)
- [chezmoi manage machine differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/) - Strategies for templates vs ignore vs separate files
- [chezmoi .chezmoiignore reference](https://www.chezmoi.io/reference/special-files/chezmoiignore/) - Pattern syntax, template support, conditional excludes
- [chezmoi unmanaged command](https://www.chezmoi.io/reference/commands/unmanaged/) - Discovering unmanaged files
- [chezmoi FAQ - Usage](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/) - Re-add workflow, merge workflow, editing approaches
- [chezmoi FAQ - Troubleshooting](https://www.chezmoi.io/user-guide/frequently-asked-questions/troubleshooting/) - Template syntax debugging, common errors

### Secondary (MEDIUM confidence)

- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) - Established `.local` override pattern (multiple repos use this convention)
- [Rick Cogley dotfiles ZSH reference](https://rickcogley.github.io/dotfiles/reference/zsh-config.html) - `.zshrc.local` sourcing pattern
- [Carmelyne Thompson - Modularizing .zshrc](https://carmelyne.com/modularizing-your-zshrc/) - Modular ZSH config pattern with loop-based sourcing
- Reddit r/neovim discussion on dotfile structure - Personal vs work split with `.local` overlay pattern (Dec 2022)

### Tertiary (LOW confidence - community wisdom, needs verification)

- Stack Overflow discussions on chezmoi add vs re-add - Various answers, some conflicting, cross-verified with official docs

## Metadata

**Confidence breakdown:**
- Standard stack (commands): HIGH - All commands documented in official chezmoi reference
- Architecture patterns: HIGH - Template conditionals and `.chezmoiignore` verified from official docs; `.local` override pattern verified from multiple established repos
- Pitfalls: MEDIUM-HIGH - Template destruction and secret leakage verified from official docs and GitHub discussions; merge direction confusion from community experience
- Code examples: HIGH - All sourced from official docs or existing repo templates

**Research date:** 2026-02-15
**Valid until:** ~60 days (chezmoi is stable; core commands unlikely to change rapidly)
