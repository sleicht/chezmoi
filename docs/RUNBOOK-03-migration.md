# Migration Runbook

**Purpose:** Safely transition from Dotbot symlinks to chezmoi-managed files on the client Mac

**Prerequisites:**
- Phase 26 audit complete (`~/migration-audit/` populated, especially `dotbot-symlinks.txt`)
- Phase 27 bootstrap complete (age key, chezmoi repo cloned, `chezmoi init` done)
- `chezmoi diff` runs without errors (confirms age decryption works)
- Dotbot's `dotfiles-zsh` repository still present (safety net)
- Terminal access on the client Mac
- Approximately 30-45 minutes to complete all procedures

**Output:** All chezmoi-managed files deployed to `~/`, Dotbot symlinks replaced with chezmoi-managed real files

---

## Procedure 1: Materialise Dotbot Symlinks (MIG-01)

**Objective:** Convert Dotbot symlinks into real files so chezmoi can safely overwrite them.

**Context:** Dotbot creates symlinks pointing into the `dotfiles-zsh` repository (e.g., `~/.zshrc -> ~/git/stuff/dotfiles-zsh/zsh/.zshrc`). chezmoi expects to write real files to these locations. If a symlink exists at a chezmoi target, chezmoi will either error or overwrite the symlink (which would modify the old repo's working tree). To avoid this, you must first "materialise" each symlink -- follow the symlink, copy the real content to a regular file at the same path, then remove the symlink.

### Steps

1. Create a backup directory for safety:
   ```bash
   mkdir -p ~/migration-audit/pre-migration-backup
   ```

2. Review the symlinks captured in Phase 26:
   ```bash
   cat ~/migration-audit/dotbot-symlinks.txt
   ```
   This shows all Dotbot-managed symlinks. Each line is a symlink path.

3. Create a script to materialise all symlinks. Save this as `~/migration-audit/materialise.sh`:
   ```bash
   #!/bin/bash
   # Materialise Dotbot symlinks into real files
   set -euo pipefail

   AUDIT_DIR=~/migration-audit
   BACKUP_DIR="$AUDIT_DIR/pre-migration-backup"
   SYMLINK_FILE="$AUDIT_DIR/dotbot-symlinks.txt"

   if [ ! -f "$SYMLINK_FILE" ]; then
     echo "ERROR: $SYMLINK_FILE not found. Run Phase 26 audit first."
     exit 1
   fi

   echo "=== Materialising Dotbot Symlinks ==="

   while IFS= read -r symlink; do
     # Skip empty lines and comments
     [[ -z "$symlink" || "$symlink" == \#* ]] && continue

     # Extract just the symlink path (handle "symlink -> target" format)
     link_path=$(echo "$symlink" | awk '{print $1}')

     # Expand ~ if present
     link_path="${link_path/#\~/$HOME}"

     if [ ! -L "$link_path" ]; then
       echo "SKIP (not a symlink): $link_path"
       continue
     fi

     if [ ! -e "$link_path" ]; then
       echo "SKIP (broken symlink): $link_path"
       continue
     fi

     # Back up the current content
     backup_path="$BACKUP_DIR${link_path#$HOME}"
     mkdir -p "$(dirname "$backup_path")"
     cp -rL "$link_path" "$backup_path"

     # Replace symlink with real file/directory
     rm -rf "$link_path"
     cp -r "$backup_path" "$link_path"

     echo "OK: $link_path (materialised)"
   done < "$SYMLINK_FILE"

   echo ""
   echo "=== Done. Backup at: $BACKUP_DIR ==="
   ```

   The script:
   - Reads each symlink from the audit file
   - Verifies the symlink target exists (skips broken symlinks)
   - Backs up the symlink target content to the backup directory
   - Replaces the symlink with a real copy of the file or directory (`cp -rL` follows symlinks recursively)

4. Make the script executable and run it:
   ```bash
   chmod +x ~/migration-audit/materialise.sh
   ~/migration-audit/materialise.sh
   ```

5. Verify no symlinks remain at chezmoi target locations:
   ```bash
   # Check common locations that were previously symlinked
   for f in ~/.zshrc ~/.zshenv ~/.gitconfig ~/.config/starship.toml; do
     if [ -L "$f" ]; then
       echo "STILL SYMLINK: $f -> $(readlink "$f")"
     elif [ -f "$f" ]; then
       echo "OK (real file): $f"
     else
       echo "ABSENT: $f"
     fi
   done
   ```

6. Spot-check a few materialised files to confirm content is intact:
   ```bash
   # Compare a materialised file against the backup
   diff ~/.zshrc ~/migration-audit/pre-migration-backup/.zshrc
   # Expected: no output (files identical)
   ```

### Expected Output

All Dotbot symlinks replaced with real files. Backup copies in `~/migration-audit/pre-migration-backup/`. No symlinks remain at chezmoi target paths.

### Troubleshooting

- **Unexpected file format in `dotbot-symlinks.txt`:** Review the file manually and adjust the `awk` parsing in the script. The Phase 26 audit may have produced lines like `/path/to/symlink -> /path/to/target` or just `/path/to/symlink`.
- **Symlink target inside a git worktree and repo is dirty:** That's fine -- the materialise script copies the current content regardless of git status.
- **`cp -L` fails with "permission denied":** Check file permissions on the symlink target. Some files may be owned by root (rare for dotfiles). Use `sudo cp -L` for those specific files.
- **Old dotfiles-zsh repo shows "deleted" files after materialisation:** This is expected since symlinks no longer point into the repo. The repo itself is untouched -- `git status` in the repo will show a clean working tree because the files are still there; only the external symlinks were replaced.

### Output

All Dotbot symlinks materialised as real files. Backup in `~/migration-audit/pre-migration-backup/`.

---

## Procedure 2: Run chezmoi apply (MIG-02)

**Objective:** Deploy all chezmoi-managed files to the home directory with client-specific templates correctly rendered.

### Steps

1. Preview what chezmoi will deploy (excluding run scripts to focus on file changes):
   ```bash
   chezmoi diff --exclude=scripts | head -100
   ```
   Review the diff output. Look for:
   - Files that will be **created** (new files not present on the client Mac)
   - Files that will be **modified** (existing files that differ from chezmoi source)
   - Template variables rendered correctly (e.g., `machine_type: client`, work email present)

2. Check the full scope of managed files:
   ```bash
   chezmoi managed --exclude=dirs | wc -l
   # Expected: ~131 files (the current chezmoi-managed count)
   ```

3. Do a dry run first to see exactly what would happen:
   ```bash
   chezmoi apply --dry-run --verbose 2>&1 | tee ~/migration-audit/chezmoi-dry-run.txt
   ```
   Review the output for any errors, especially:
   - Age decryption failures on encrypted files
   - Template rendering errors
   - rbw lookup failures (if the agent has locked, re-unlock with `rbw unlock`)

4. If the dry run looks clean, apply:
   ```bash
   chezmoi apply --verbose 2>&1 | tee ~/migration-audit/chezmoi-apply.txt
   ```
   This will:
   - Deploy all managed files to their target locations
   - Run lifecycle scripts (Homebrew bootstrap, package install, permission verification)
   - Decrypt and deploy encrypted files (SSH keys, etc.)

   **Note:** The lifecycle scripts may take several minutes, especially the Homebrew package installation. Monitor the output for errors.

5. Verify key files were deployed correctly:
   ```bash
   echo "=== Post-Apply Verification ==="

   # Check critical files exist and are NOT symlinks
   for f in ~/.zshrc ~/.zshenv ~/.gitconfig ~/.config/starship.toml ~/.ssh/config; do
     if [ -f "$f" ] && [ ! -L "$f" ]; then
       echo "OK: $f"
     elif [ -L "$f" ]; then
       echo "WARN (symlink): $f -> $(readlink "$f")"
     else
       echo "MISSING: $f"
     fi
   done

   # Verify client-specific template rendering
   echo ""
   echo "--- Template checks ---"
   grep "machine_type" ~/.config/chezmoi/chezmoi.yaml
   # Should confirm machine_type=client in config

   # Verify encrypted files were decrypted
   if [ -f ~/.ssh/id_rsa ]; then
     echo "OK: SSH private key deployed"
   else
     echo "MISSING: ~/.ssh/id_rsa"
   fi
   ```

6. Switch the chezmoi repo remote from HTTPS to SSH (now that SSH keys are deployed):
   ```bash
   cd ~/.local/share/chezmoi
   git remote set-url origin git@github.com:sleicht/chezmoi.git
   # Verify the switch
   git remote -v
   # Test SSH access
   ssh -T git@github.com 2>&1 || true
   ```

### Expected Output

All ~131 managed files deployed. Critical files present as real files (not symlinks). SSH keys decrypted and deployed. Chezmoi repo remote switched to SSH.

### Troubleshooting

- **`chezmoi apply` fails with age decryption errors:** Re-check `~/.config/age/key-client.txt` permissions (must be 600) and content. Re-run the Phase 27 verification command.
- **rbw lookups fail (`rbw: command not found` or agent locked):** Run `rbw unlock` and retry.
- **Lifecycle scripts fail (Homebrew install errors):** These are non-fatal for the core file deployment. Note the errors and debug after the main apply completes. You can re-run scripts with `chezmoi apply --include=scripts`.
- **Some files show as "would modify" but don't get applied:** chezmoi may be prompting for confirmation. Use `chezmoi apply --force` for those specific files (see Procedure 3 for conflict handling).
- **`ssh -T git@github.com` fails after deploying SSH keys:** Check `~/.ssh/config` and `~/.ssh/id_rsa` permissions. Run `chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub`.

### Output

Chezmoi-managed files deployed. `~/migration-audit/chezmoi-apply.txt` contains full apply log for reference.

---

## Procedure 3: Handle Conflicts (MIG-03)

**Objective:** Resolve cases where chezmoi targets already exist as real files (not symlinks) that differ from the chezmoi source.

**Context:** After materialising symlinks (Procedure 1), some files may have been edited locally and differ from what chezmoi would deploy. Additionally, some files may exist on the client Mac that were never Dotbot-managed but overlap with chezmoi targets (e.g., manually created `.gitconfig`). This procedure documents how to identify and resolve these conflicts.

### Steps

1. Identify conflicts by reviewing the diff between current files and chezmoi source:
   ```bash
   # Show files where local content differs from chezmoi source
   chezmoi diff --exclude=scripts > ~/migration-audit/chezmoi-conflicts.txt
   ```
   If this file is empty (or only shows new files), there are no conflicts -- skip to step 5.

2. Categorise each conflict. For each file in the diff:
   ```bash
   # View the diff for a specific file
   chezmoi diff ~/.zshrc
   ```
   Classify as:
   - **Safe to overwrite:** Local file has no valuable edits (e.g., it's the old Dotbot version and chezmoi has the updated version). Action: let chezmoi apply overwrite it.
   - **Merge needed:** Local file has valuable edits not yet in chezmoi source. Action: note for Phase 29 (Reintegration), then let chezmoi overwrite for now.
   - **Keep local:** Local file should NOT be overwritten (rare -- usually means chezmoi source needs updating). Action: add to `.chezmoiignore` temporarily, or update the chezmoi source.

3. For files with valuable local edits, save the local version before overwriting:
   ```bash
   # Save the local version for later reintegration (Phase 29)
   mkdir -p ~/migration-audit/local-edits
   cp ~/.some/config ~/migration-audit/local-edits/some-config
   ```

4. Apply chezmoi with force for conflicting files:
   ```bash
   # Force apply overwrites existing files without prompting
   chezmoi apply --force
   ```
   Or apply individual files if you want to be selective:
   ```bash
   chezmoi apply ~/.gitconfig
   chezmoi apply ~/.zshrc
   ```

5. Verify the final state -- no remaining differences between chezmoi source and deployed files:
   ```bash
   chezmoi diff --exclude=scripts
   # Expected: empty output (no differences)
   ```
   If the diff is empty, chezmoi and the deployed files are fully in sync.

6. Record any files saved for reintegration:
   ```bash
   ls ~/migration-audit/local-edits/ 2>/dev/null
   ```
   If this directory has files, they contain local edits that need to be merged into chezmoi source in Phase 29. Note these down.

### Expected Output

`chezmoi diff --exclude=scripts` produces empty output. All managed files match chezmoi source. Valuable local edits saved to `~/migration-audit/local-edits/` for Phase 29.

### Troubleshooting

- **`chezmoi apply --force` still fails on a specific file:** Check if the target directory exists (`mkdir -p $(dirname ~/.path/to/file)`) and if you have write permissions.
- **A file keeps showing as modified after apply:** It may be a templated file that renders differently due to missing template data. Check `chezmoi execute-template < ~/.local/share/chezmoi/path/to/file.tmpl` to debug.
- **Accidentally overwrote a file with valuable edits:** The Phase 26 audit and the pre-migration backup (Procedure 1) should have copies. Check `~/migration-audit/pre-migration-backup/` and `~/migration-audit/dotfiles-drift-diff.txt`.

### Output

All conflicts resolved. Local edits preserved in `~/migration-audit/local-edits/` for Phase 29 reintegration.

---

## Summary

After completing all 3 procedures, you should have:
- All Dotbot symlinks materialised and replaced by chezmoi-managed files
- ~131 files deployed via `chezmoi apply` with client-specific templates rendered
- Any conflicts resolved, with valuable local edits saved for Phase 29
- Chezmoi repo remote switched from HTTPS to SSH
- Full apply log at `~/migration-audit/chezmoi-apply.txt`

### Verification Command

Run this command to verify all migration goals are met:

```bash
echo "=== Migration Verification ==="

# No symlinks pointing into dotfiles-zsh repo
symlinks_remaining=$(find ~ -maxdepth 3 -type l -exec readlink {} \; 2>/dev/null | grep -c "dotfiles-zsh" || true)
echo "Symlinks still pointing to dotfiles-zsh: $symlinks_remaining"

# Chezmoi fully in sync
if chezmoi diff --exclude=scripts 2>/dev/null | head -1 | grep -q '^'; then
  echo "WARN: chezmoi diff shows remaining differences"
else
  echo "OK: chezmoi fully in sync (no diff)"
fi

# Critical files present
for f in ~/.zshrc ~/.gitconfig ~/.ssh/config ~/.config/starship.toml; do
  if [ -f "$f" ] && [ ! -L "$f" ]; then
    echo "OK: $f (real file)"
  else
    echo "ISSUE: $f"
  fi
done

# SSH keys deployed
if [ -f ~/.ssh/id_rsa ] && [ "$(stat -f '%Lp' ~/.ssh/id_rsa 2>/dev/null)" = "600" ]; then
  echo "OK: SSH key deployed with correct permissions"
else
  echo "ISSUE: SSH key missing or wrong permissions"
fi

# Git remote is SSH
remote=$(cd ~/.local/share/chezmoi && git remote get-url origin 2>/dev/null)
if echo "$remote" | grep -q "^git@"; then
  echo "OK: chezmoi repo using SSH remote"
else
  echo "INFO: chezmoi repo still using HTTPS ($remote)"
fi
```

---

## Next Steps

- The old `dotfiles-zsh` repository is intentionally left in place as a rollback safety net (Phase 31 documents when to remove it)
- Do NOT delete `~/migration-audit/` yet -- Phase 29 uses `local-edits/` for reintegration
- Proceed to **Phase 29: Reintegration** to merge custom scripts, env vars, and valuable local edits into chezmoi source

---

*Migration runbook created: 2026-02-15*
