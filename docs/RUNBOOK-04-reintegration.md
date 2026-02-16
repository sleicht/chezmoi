# Reintegration Runbook

**Purpose:** Evaluate and merge local customisations captured during the migration audit back into chezmoi-managed dotfiles

**Prerequisites:**
- Phase 28 migration complete (`chezmoi diff --exclude=scripts` produces empty output)
- `~/migration-audit/` directory still present (contains audit artefacts and local edits)
- Terminal access on the client Mac
- Approximately 30-60 minutes (varies depending on number of items to triage)

**Output:** All valuable local customisations either added to chezmoi source, documented as intentionally local, or explicitly discarded

---

## Procedure 1: Evaluate Custom Scripts (REINT-01)

**Objective:** Review custom scripts identified in Phase 26 and decide for each: add to chezmoi, keep locally, or discard.

**Context:** Phase 26 Procedure 2 created `~/migration-audit/untracked-scripts.txt` listing scripts in `~/bin`, `~/.bin`, and `~/.local/bin` that are NOT tracked in the old dotfiles-zsh repo. These are scripts the user created locally. They need to be triaged: some may be valuable and should be managed by chezmoi, some are machine-specific and should stay local, and some are obsolete and can be removed.

### Steps

1. Review the untracked scripts list:
   ```bash
   cat ~/migration-audit/untracked-scripts.txt
   ```
   If the file is empty or says "no untracked scripts found", skip to the output section.

2. For each script, examine its content and decide:
   ```bash
   # Review a script
   cat ~/bin/script-name
   # or
   head -30 ~/bin/script-name
   ```

   Decision criteria:
   - **Add to chezmoi** -- Script is useful across machines OR should be version-controlled. Use `chezmoi add` to bring it under management.
   - **Keep local** -- Script is specific to this machine only (e.g., references local paths, company-internal tools). Leave it in place; document in a local inventory.
   - **Discard** -- Script is obsolete, superseded, or no longer needed. Remove it.

3. For scripts to add to chezmoi:
   ```bash
   # Add a script to chezmoi management
   chezmoi add ~/bin/script-name
   # This copies it to ~/.local/share/chezmoi/ and auto-commits (autoCommit is on)

   # If the script is client-machine-only, also add to .chezmoiignore for personal machines:
   # In .chezmoiignore, under the personal machine section:
   # {{ if ne .machine_type "client" }}
   # bin/script-name
   # {{ end }}
   ```

   If the script needs to be executable (most scripts do), chezmoi will detect this automatically if the file already has +x. Verify:
   ```bash
   chezmoi managed | grep script-name
   # Should appear in managed list
   ls -la $(chezmoi source-path ~/bin/script-name)
   # Source file should have executable_ prefix if script has +x
   ```

4. For scripts to keep local, create a record:
   ```bash
   # Document local-only scripts for future reference
   echo "# Local-only scripts (not managed by chezmoi)" > ~/migration-audit/local-scripts-inventory.txt
   echo "# These scripts are intentionally kept outside chezmoi management" >> ~/migration-audit/local-scripts-inventory.txt
   echo "" >> ~/migration-audit/local-scripts-inventory.txt
   # Add each local script:
   echo "~/bin/local-script -- reason: [company-specific tool wrapper]" >> ~/migration-audit/local-scripts-inventory.txt
   ```

5. For scripts to discard:
   ```bash
   # Remove obsolete scripts (review before deleting!)
   rm ~/bin/obsolete-script
   ```

6. Verify the triage is complete:
   ```bash
   echo "=== Script Triage Complete ==="
   echo "Managed by chezmoi:"
   chezmoi managed | grep -E '(bin/|\.bin/)' || echo "  (none added)"
   echo ""
   echo "Local-only scripts:"
   cat ~/migration-audit/local-scripts-inventory.txt 2>/dev/null || echo "  (none documented)"
   ```

### Expected Output

Every script in `untracked-scripts.txt` has been triaged. Scripts added to chezmoi appear in `chezmoi managed`. Local-only scripts are documented. Discarded scripts are removed.

### Troubleshooting

- If `chezmoi add` fails with "not in home directory": the script must be under `~/` for chezmoi to manage it. Move it to a managed location first.
- If a script needs machine-type conditional deployment: add it via `chezmoi add`, then edit `.chezmoiignore` to exclude it on non-client machines (see step 3).
- If a script has secrets/tokens embedded: do NOT add to chezmoi directly. Extract the secret to a Bitwarden item and template the script (convert to `.tmpl` suffix).
- If `chezmoi add` does not set `executable_` prefix: manually rename the source file to include the prefix: `cd ~/.local/share/chezmoi && mv bin/script executable_bin/script` (or wherever chezmoi placed it).

### Output

All custom scripts triaged. `~/migration-audit/local-scripts-inventory.txt` documents any scripts kept locally.

---

## Procedure 2: Reintegrate Environment Variables (REINT-02)

**Objective:** Review machine-specific environment variables and integrate them into chezmoi via templates or a local override file.

**Context:** Phase 26 Procedure 3 captured environment variables to several files:
- `~/migration-audit/client-exports.txt` -- export statements from shell configs
- `~/migration-audit/client-private-exports.txt` -- exports from private override files
- `~/migration-audit/client-critical-vars.txt` -- important variables (proxies, SDKs, tokens)

The chezmoi repo uses:
- `dot_zsh.d/variables.zsh` for interactive shell variables (non-templated, shared across machines)
- `dot_zshrc.tmpl` with `{{ if eq .machine_type "client" }}` blocks for client-only code (e.g., san-proxy)
- `dot_Brewfile.tmpl` for machine-conditional package lists
- `.chezmoidata.yaml` for static data referenced in templates
- `private_dot_gitconfig_local.tmpl` for machine-conditional git settings

The goal is NOT to blindly copy all env vars into chezmoi. Most environment variables are set by tools (mise, Homebrew, system) and don't need manual management. The user should focus on variables they explicitly set that are unique to the client machine.

### Steps

1. Review the critical variables file first (these are the most likely candidates for reintegration):
   ```bash
   cat ~/migration-audit/client-critical-vars.txt
   ```
   These are variables matching patterns like `PROXY`, `JAVA_HOME`, `ANDROID_HOME`, `_TOKEN`, `_KEY`, `_SECRET`.

2. Review the private exports (these are variables set in local override files that won't be in chezmoi):
   ```bash
   cat ~/migration-audit/client-private-exports.txt
   ```

3. For each variable, classify:
   - **Already handled by chezmoi** -- Variable is set by a chezmoi-managed file or tool (e.g., PATH entries set by mise, EDITOR set in `variables.zsh`). Action: skip.
   - **Add to chezmoi template** -- Variable is client-specific and should be templated. Action: add to a `.zsh.d/` module with machine_type conditional, or add to an existing template.
   - **Add to local override file** -- Variable is truly local (contains secrets, ephemeral paths, or machine-specific values that change frequently). Action: create/update a local override file.
   - **No longer needed** -- Variable was for the old setup and is obsolete. Action: skip.

4. For variables to add to chezmoi as a template:

   **Option A -- Add to an existing `.zsh.d/` module (preferred for simple variables):**
   ```bash
   # Edit the chezmoi source directly
   chezmoi edit ~/.zsh.d/variables.zsh
   ```
   Add a machine_type conditional block at the bottom:
   ```zsh
   # === Client-specific variables ===
   # (Only rendered on client machines via chezmoi template)
   ```
   **Important:** If adding template conditionals, the file must use the `.tmpl` suffix. Convert it:
   ```bash
   cd ~/.local/share/chezmoi
   git mv dot_zsh.d/variables.zsh dot_zsh.d/variables.zsh.tmpl
   ```
   Then add Go template syntax:
   ```
   {{- if eq .machine_type "client" }}
   export SOME_CLIENT_VAR="value"
   {{- end }}
   ```

   **Option B -- Create a new client-only module (preferred for many client-specific variables):**
   ```bash
   # Create a new zsh.d module for client-specific variables
   cat > /tmp/client-vars.zsh << 'EOF'
   #!/usr/bin/env zsh
   # Managed by chezmoi - client-machine-only variables
   # This file is only deployed on machines with machine_type=client

   export SOME_CLIENT_VAR="value"
   export ANOTHER_VAR="value"
   EOF

   # Add to chezmoi (it will be placed under dot_zsh.d/)
   cp /tmp/client-vars.zsh ~/.zsh.d/client-vars.zsh
   chezmoi add ~/.zsh.d/client-vars.zsh
   ```
   Then add `client-vars.zsh` to `.chezmoiignore` for non-client machines:
   ```
   {{ if ne .machine_type "client" }}
   .zsh.d/client-vars.zsh
   {{ end }}
   ```

5. For variables that should stay in a local override file (NOT managed by chezmoi):

   Create a local override pattern. The existing `.zshrc.tmpl` sources `~/.profile` and then loads Sheldon plugins which source `~/.zsh.d/*.zsh` modules. A local override can be sourced at the end of `.zshrc` or as a separate file:

   ```bash
   # Create a local override file for secrets and ephemeral variables
   cat > ~/.zsh.d.local << 'EOF'
   # Local overrides -- NOT managed by chezmoi
   # This file is intentionally outside chezmoi management
   # Add machine-specific variables, secrets, and temporary overrides here

   # Example:
   # export COMPANY_API_TOKEN="..."
   # export LOCAL_PROJECT_PATH="/some/local/path"
   EOF
   ```

   Then ensure `.zshrc` sources it. If the user wants this to be part of chezmoi, add a source line to `dot_zshrc.tmpl`:
   ```bash
   chezmoi edit ~/.zshrc
   ```
   Add near the bottom (before startup monitoring):
   ```zsh
   # === Local overrides (not managed by chezmoi) ===
   [[ -f "$HOME/.zsh.d.local" ]] && source "$HOME/.zsh.d.local"
   ```
   Then apply:
   ```bash
   chezmoi apply ~/.zshrc
   ```

   **Important:** The local override file itself should NOT be added to chezmoi. Only the source line in `.zshrc` is managed.

6. Verify the reintegration:
   ```bash
   # Start a new shell to load changes
   exec zsh

   # Check that critical variables are set
   echo "SOME_CLIENT_VAR=$SOME_CLIENT_VAR"
   # Repeat for each variable you reintegrated
   ```

### Expected Output

Client-specific environment variables are either templated in chezmoi or documented in a local override file. A new shell session loads all variables correctly.

### Troubleshooting

- If a `.zsh.d/` module needs to become a template: rename to `.zsh.tmpl` suffix in the chezmoi source, not the target. Use `cd ~/.local/share/chezmoi && git mv dot_zsh.d/file.zsh dot_zsh.d/file.zsh.tmpl`.
- If `chezmoi apply` fails after editing a template: check Go template syntax. Common errors: missing `{{ end }}`, unbalanced braces, wrong variable name. Debug with `chezmoi execute-template < ~/.local/share/chezmoi/dot_zsh.d/file.zsh.tmpl`.
- If env vars contain secrets: NEVER add secret values to chezmoi source files or `.chezmoidata.yaml`. Use Bitwarden lookups in templates (see `private_dot_gitconfig_local.tmpl` for the pattern) or keep in the local override file.
- If the local override file gets overwritten by chezmoi apply: it shouldn't, because it's not in chezmoi's managed list. But if you accidentally added it, remove with `chezmoi forget ~/.zsh.d.local`.

### Output

Environment variables reintegrated. Critical client-specific variables are either in chezmoi templates or in `~/.zsh.d.local`.

---

## Procedure 3: Merge Drifted Config Edits (REINT-03)

**Objective:** Review files saved during Phase 28 conflict resolution and merge valuable edits into chezmoi source.

**Context:** Phase 28 Procedure 3 saved local edits to `~/migration-audit/local-edits/` before letting chezmoi overwrite them. Additionally, Phase 26 Procedure 4 captured a full diff of uncommitted changes in `~/migration-audit/dotfiles-drift-diff.txt` and a triage checklist in `~/migration-audit/drift-triage.md`. Now the user must review each saved edit and decide whether to merge it into the chezmoi source.

### Steps

1. List the saved local edits from Phase 28:
   ```bash
   ls -la ~/migration-audit/local-edits/ 2>/dev/null
   ```
   If this directory is empty or doesn't exist, the user had no conflicts during migration -- skip to step 4 and check the drift diff instead.

2. For each file in `local-edits/`, compare it against the current chezmoi-deployed version:
   ```bash
   # Example: compare a saved local edit against what chezmoi deployed
   diff ~/migration-audit/local-edits/some-config ~/.some/config
   ```
   This shows what the local version had that chezmoi's version doesn't. Review each difference:
   - **Valuable edit** -- A setting, alias, or configuration that should be in chezmoi. Action: merge into chezmoi source.
   - **Stale/superseded** -- An old setting that chezmoi's version has already updated or replaced. Action: discard.
   - **Machine-specific** -- A setting unique to this machine (e.g., local path, machine name). Action: template it or move to local override.

3. For valuable edits, merge into chezmoi source using one of these approaches:

   **Approach A -- Manual edit (simple changes):**
   ```bash
   # Edit the chezmoi source file directly
   chezmoi edit ~/.some/config
   # Add the valuable lines from the local edit
   # Save and close
   chezmoi apply ~/.some/config
   ```

   **Approach B -- chezmoi merge (complex changes):**
   ```bash
   # Three-way merge between chezmoi source, deployed file, and local edit
   # First, temporarily replace the deployed file with the local edit:
   cp ~/migration-audit/local-edits/some-config ~/.some/config
   # Then use chezmoi merge to interactively resolve:
   chezmoi merge ~/.some/config
   # This opens a three-way merge tool (if configured) or shows the diff
   ```
   Note: `chezmoi merge` requires a merge tool configured in `~/.config/chezmoi/chezmoi.yaml`. If not configured, use manual edit (Approach A) instead.

   **Approach C -- Overwrite chezmoi source (when local version is definitively better):**
   ```bash
   # Replace the chezmoi source entirely with the local version
   cp ~/migration-audit/local-edits/some-config $(chezmoi source-path ~/.some/config)
   # Verify the source was updated
   chezmoi diff ~/.some/config
   # Should show no diff (or expected template differences)
   chezmoi apply ~/.some/config
   ```

4. Also check the Phase 26 drift diff for any edits that weren't captured in `local-edits/` (they may have been in files that chezmoi doesn't manage, or were in the old repo's working tree):
   ```bash
   # Review the drift triage checklist
   cat ~/migration-audit/drift-triage.md 2>/dev/null

   # Review the full diff (may be large)
   less ~/migration-audit/dotfiles-drift-diff.txt
   ```
   If the drift triage checklist has items marked as "keep" or "review", evaluate them now using the same criteria as step 2.

5. After all merges, verify chezmoi is fully in sync:
   ```bash
   chezmoi diff --exclude=scripts
   # Expected: empty output (no differences)
   ```
   If there are still differences, review each one:
   ```bash
   chezmoi diff --exclude=scripts | head -50
   ```
   Either apply to accept chezmoi's version or edit the source to incorporate the local change.

6. Start a new shell and verify everything works:
   ```bash
   exec zsh
   # Test that aliases, functions, and variables still work as expected
   ```

### Expected Output

All valuable local edits merged into chezmoi source. `chezmoi diff --exclude=scripts` produces empty output. The shell behaves as expected with all customisations intact.

### Troubleshooting

- If `chezmoi merge` is not available or not configured: use manual editing (Approach A). Open the chezmoi source with `chezmoi edit`, then reference the local edit file side by side.
- If merging a template file: be careful not to break Go template syntax. After editing, verify with `chezmoi execute-template < $(chezmoi source-path ~/.some/config)`.
- If you merge an edit but `chezmoi diff` still shows a difference: the file may be a template whose output depends on variables. Check the rendered output with `chezmoi cat ~/.some/config` and compare to the deployed version.
- If the drift diff is very large: focus on files you use daily (`.zshrc`, `.gitconfig`, IDE configs). Stale edits in rarely-used configs are usually safe to discard.
- If you accidentally break a file: `chezmoi apply --force ~/.some/config` will restore it to the chezmoi source version. Then try the merge again more carefully.

### Output

All drifted config edits reviewed and resolved. chezmoi source is up to date with all valuable local customisations.

---

## Summary

After completing all 3 procedures, the user should have:
- All custom scripts triaged: added to chezmoi, documented as local-only, or discarded
- Machine-specific env vars either templated in chezmoi (with machine_type conditionals) or in a local override file (`~/.zsh.d.local`)
- All valuable config edits from `~/migration-audit/local-edits/` and the drift diff merged into chezmoi source
- `chezmoi diff --exclude=scripts` produces empty output (fully in sync)
- A clean shell session with all customisations working

---

## Verification

```bash
echo "=== Reintegration Verification ==="

# chezmoi fully in sync
if chezmoi diff --exclude=scripts 2>/dev/null | head -1 | grep -q '^'; then
  echo "WARN: chezmoi diff shows remaining differences"
  chezmoi diff --exclude=scripts | head -20
else
  echo "OK: chezmoi fully in sync (no diff)"
fi

# Check for unresolved local edits
if [ -d ~/migration-audit/local-edits ] && [ "$(ls -A ~/migration-audit/local-edits 2>/dev/null)" ]; then
  echo "INFO: ~/migration-audit/local-edits/ still has files -- verify all were reviewed"
  ls ~/migration-audit/local-edits/
else
  echo "OK: no unresolved local edits"
fi

# Check untracked scripts were triaged
if [ -f ~/migration-audit/untracked-scripts.txt ] && [ -s ~/migration-audit/untracked-scripts.txt ]; then
  script_count=$(grep -c "CUSTOM" ~/migration-audit/untracked-scripts.txt 2>/dev/null || echo "0")
  echo "INFO: $script_count custom scripts were identified in Phase 26 audit -- verify all triaged"
else
  echo "OK: no custom scripts to triage (or already handled)"
fi

# Verify shell loads cleanly
echo ""
echo "--- Shell health check ---"
zsh -i -c 'echo "OK: shell starts without errors"' 2>&1
```

---

## Next Steps

- The `~/migration-audit/` directory can now be archived or kept for reference, but is no longer actively needed
- Proceed to **Phase 30: Verification** to run the full smoke test suite confirming shell, git, tools, and encryption all work correctly
- If any reintegration items were deferred or need further work, note them before moving to Phase 30
