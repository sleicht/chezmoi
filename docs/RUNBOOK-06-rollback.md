# Rollback Runbook

**Phase:** 31-rollback-documentation
**Purpose:** Document safety net procedures for reverting to the old Dotbot setup if the chezmoi migration fails, and define clear criteria for when to rollback vs. debug forward
**Created:** 2026-02-16

## Purpose

This runbook provides:
1. A clear decision framework for when to rollback vs. debug forward
2. Step-by-step procedures to safely undo the chezmoi migration and restore the Dotbot-managed dotfiles setup

**Critical context:** Most migration issues are fixable within chezmoi. Full rollback is a significant step that undoes all migration work. This runbook exists as a safety net — use it only when truly necessary.

## Prerequisites

- The frozen `dotfiles-zsh` (Dotbot) repository is still present on the client Mac (DO NOT delete until confident the migration is stable)
- The `~/migration-audit/` directory from Phase 26 still exists (contains symlink inventory and pre-migration backup)
- Terminal access on the client Mac
- Familiarity with RUNBOOK-05-verification.md (to know what "success" looks like)

## Output

- Confidence that the migration can be safely undone if needed
- Clear decision framework for rollback vs. debug
- Working Dotbot setup if rollback is executed

---

## Procedure 1: Rollback Decision Criteria

**Requirement:** ROLL-02
**Objective:** Define clear, specific criteria for when to abandon the chezmoi migration and revert to Dotbot vs. when to debug forward

### Context

Most migration issues are configuration problems that can be fixed within chezmoi. A full rollback is a significant step that undoes all migration work. You need a clear framework to avoid two failure modes:
1. Panic-reverting over a fixable issue
2. Stubbornly debugging when the migration is fundamentally broken

**Note:** This procedure is intentionally placed FIRST even though it is ROLL-02, because you should consult the decision criteria BEFORE attempting a rollback. The decision must come before the action.

### Steps

#### Category 1: Debug Forward (DO NOT rollback)

These issues are fixable within chezmoi and do not warrant rollback:

- **Individual tool missing** — e.g., `brew install <tool>` fixes it
- **Shell plugin not loading** — Sheldon config issue, fix in `plugins.toml`
- **Prompt not rendering** — oh-my-posh config or path issue
- **Git identity wrong** — Fix in `.gitconfig` or `.gitconfig_local`
- **Startup time slow** — Performance tuning, not a migration failure
- **One or two smoke test checks failing** — Targeted fix, not systemic failure
- **`chezmoi diff` shows minor differences** — Run `chezmoi apply` again
- **Permission issues on specific files** — Fix with `chmod`
- **Missing environment variables** — Add to local override file or chezmoi template

**Common thread:** The issue affects ONE subsystem and has a clear remediation path.

#### Category 2: Consider Rollback (evaluate carefully)

These issues may indicate a deeper problem:

- **Shell fails to start entirely** — `exec zsh` produces error, falls back to bash
- **Age decryption fails** — Can't decrypt SSH keys or secrets (but try reprovisioning age key first)
- **Multiple subsystems broken simultaneously** — Shell + git + tools all failing
- **`chezmoi apply` produces template errors on many files** — machine_type or data file issues
- **SSH keys deployed but don't work AND age key is also broken** — Compound failure

**Common thread:** Multiple systems affected, or a foundational piece (encryption, templating) is broken.

**Decision process:** Try ONE round of debugging first. If the root cause is identified and fixable, debug forward. If the root cause is unclear after 30 minutes, consider rollback.

#### Category 3: Rollback Immediately

These situations warrant immediate rollback:

- **Upcoming deadline or critical meeting and the shell/git is non-functional** — Revert now, debug later
- **`chezmoi apply` has corrupted files that were NOT backed up** in `~/migration-audit/pre-migration-backup/`
- **Age identity key is lost** (not in Bitwarden, not recoverable) AND encrypted files are needed immediately
- **Dotbot repository has been accidentally deleted or corrupted** — Rollback impossible, escalate instead

**Common thread:** Time pressure + non-functional state, or data loss.

### Decision Flowchart

```
Migration issue detected
        │
        ▼
Is the shell functional? (can you run commands?)
  ├─ YES → Is git functional? (can you commit/push?)
  │   ├─ YES → Debug forward (Category 1)
  │   └─ NO → Is SSH key / age decryption working?
  │       ├─ YES → Debug forward (git config issue)
  │       └─ NO → Try reprovisioning age key (Phase 27)
  │           ├─ Fixed → Debug forward
  │           └─ Still broken → Consider rollback (Category 2)
  └─ NO → Is it a single error message on startup?
      ├─ YES → Debug forward (likely a config syntax error)
      └─ NO (shell won't start at all) →
          Do you have a time-critical deadline?
          ├─ YES → Rollback immediately (Category 3)
          └─ NO → Try 30 min debug, then rollback if no progress
```

### Expected Output

You have a clear mental model for when to rollback vs. debug forward. This procedure produces no files — it is a reference to consult when issues arise.

### Troubleshooting

**If you are unsure whether to rollback:** The safest default is: "Can you still work?" If yes, debug forward. If no, rollback.

### Output

Decision framework internalised. No files produced — this is a reference procedure.

---

## Procedure 2: Restore Dotbot Symlinks

**Requirement:** ROLL-01
**Objective:** Step-by-step instructions to undo the chezmoi migration and restore the old Dotbot symlink-based setup

### Context

During Phase 28, the migration followed this path:
1. Materialised Dotbot symlinks to real files via `cp -L`
2. Removed the symlinks
3. Ran `chezmoi apply` to deploy chezmoi-managed files

Rollback reverses this:
1. Remove chezmoi-managed files
2. Restore Dotbot symlinks from the frozen repository

The old `dotfiles-zsh` repository is still present and the `~/migration-audit/pre-migration-backup/` directory contains the pre-materialisation state.

### Steps

#### Step 1: Stop chezmoi from managing files

```bash
# Prevent chezmoi from auto-applying or interfering during rollback
# Move the chezmoi source directory aside (don't delete — you may want it later)
mv ~/.local/share/chezmoi ~/.local/share/chezmoi.disabled
```

**Expected:** chezmoi commands will error with "no source directory" — this is correct.

#### Step 2: Identify files chezmoi deployed

```bash
# Use the managed file list captured during migration (or regenerate)
# If you still have the chezmoi source:
cd ~/.local/share/chezmoi.disabled
chezmoi managed --exclude=dirs 2>/dev/null > ~/migration-audit/rollback-file-list.txt

# Or if chezmoi is completely broken, use the audit artefact:
cat ~/migration-audit/chezmoi-managed.txt
```

#### Step 3: Remove chezmoi-deployed files (with backup)

```bash
mkdir -p ~/migration-audit/chezmoi-backup-$(date +%Y%m%d)

# For each chezmoi-managed file, back it up then remove
while IFS= read -r file; do
  target="$HOME/$file"
  if [ -f "$target" ] || [ -L "$target" ]; then
    # Preserve directory structure in backup
    backup_dir="$HOME/migration-audit/chezmoi-backup-$(date +%Y%m%d)/$(dirname "$file")"
    mkdir -p "$backup_dir"
    cp -a "$target" "$backup_dir/"
    rm "$target"
    echo "Removed: $target"
  fi
done < ~/migration-audit/rollback-file-list.txt
```

**Note:** This backs up chezmoi files before removing them, so nothing is permanently lost.

#### Step 4: Restore Dotbot symlinks

```bash
cd ~/dotfiles-zsh  # Or wherever the frozen Dotbot repo lives

# Option A: If Dotbot's install script still works
./install  # Dotbot reads install.conf.yaml and recreates symlinks

# Option B: If Dotbot is broken or unavailable, manually recreate symlinks
# Use the symlink inventory from Phase 26:
cat ~/migration-audit/dotbot-symlinks.txt
# For each line (format: symlink -> target), recreate:
# ln -sf <target_in_repo> <symlink_location>
```

**Expected:** Dotbot recreates symlinks pointing into the `dotfiles-zsh` repository.

#### Step 5: Verify Dotbot symlinks are in place

```bash
# Check a few key files are symlinks again
for f in ~/.zshrc ~/.gitconfig ~/.config/sheldon/plugins.toml; do
  if [ -L "$f" ]; then
    echo "OK (symlink): $f -> $(readlink "$f")"
  elif [ -f "$f" ]; then
    echo "WARNING (real file, not symlink): $f"
  else
    echo "MISSING: $f"
  fi
done
```

#### Step 6: Restore shell functionality

```bash
# Start a fresh shell to load the Dotbot-managed config
exec zsh

# Verify basic functionality
echo "Shell: $SHELL"
alias | head -5
git config user.email
```

**Note:** If the shell has errors, the Dotbot config may need the old plugin manager (zgenom) reinstalled. Check `~/dotfiles-zsh/README.md` for the original setup instructions.

#### Step 7: Handle chezmoi-specific files that Dotbot doesn't manage

Some files may have been added by chezmoi that didn't exist under Dotbot (e.g., mise config, chezmoi-specific scripts). These won't be restored by Dotbot and will be missing. This is expected — the old Dotbot setup didn't have these features.

**Key differences to expect after rollback:**
- mise task runner will not be available (Dotbot setup used different tooling)
- Shell startup monitoring (`LAST_SHELL_STARTUP_MS`) will not exist
- Evalcache optimisations will not be present
- Age encryption infrastructure will not be active
- Some Homebrew packages added during v1.0-v2.1 may still be installed but unconfigured

#### Step 8: Clean up (optional, after confirming rollback is stable)

```bash
# Only after confirming Dotbot setup works:
# Remove the disabled chezmoi source (or keep for future reference)
# rm -rf ~/.local/share/chezmoi.disabled

# Remove chezmoi config
# rm -rf ~/.config/chezmoi

# These are optional — keeping them doesn't cause harm
```

### Expected Output

The client Mac is back to the Dotbot-managed setup. Shell starts, dotfiles are symlinked from the `dotfiles-zsh` repository, and the pre-chezmoi workflow is restored.

### Troubleshooting

**If Dotbot `./install` fails:**
- Check that Python is available: `python3 --version`
- Dotbot requires Python. If Python was managed by mise and mise config was removed, install Python via Homebrew first: `brew install python3`

**If shell errors after restoring Dotbot:**
- The old zgenom plugin manager may need reinitialisation
- Check if `~/.zgenom` exists; if not, clone it: `git clone https://github.com/jandamm/zgenom.git ~/.zgenom`

**If symlinks point to wrong locations:**
- Verify the `dotfiles-zsh` repository path
- The symlink targets in `dotbot-symlinks.txt` use absolute paths — if the repository has moved, update them

**If git stops working after rollback:**
- The `.gitconfig` may reference chezmoi-specific includes
- Check `git config --list --show-origin` for broken includes and remove them

**If age-encrypted secrets are needed but age is no longer configured:**
- The age key at `~/.config/age/key-client.txt` should still exist (rollback doesn't remove it)
- Use `age --decrypt -i ~/.config/age/key-client.txt < encrypted-file` to manually decrypt if needed

### Output

Client Mac restored to Dotbot-managed dotfiles. Old workflow functional.

---

## Summary

This runbook provides two complementary procedures:
1. **Decision criteria** (consult FIRST): A framework for deciding whether to rollback or debug forward, with three severity categories and a text-based flowchart
2. **Rollback procedure** (execute IF needed): Step-by-step instructions to undo chezmoi and restore Dotbot symlinks

### Key Safety Notes

- The `dotfiles-zsh` repository MUST remain on disk until you are fully confident the chezmoi migration is stable (suggest keeping it for at least 2 weeks after verification)
- The `~/migration-audit/` directory contains backups and inventories that make rollback possible — do not delete it prematurely
- Rollback is a one-way operation: after restoring Dotbot, the chezmoi features (v2.0 performance, v2.1 mise tasks) will not be available until re-migration
- Most migration issues are fixable without rollback — consult Procedure 1 before executing Procedure 2

## Next Steps

- Keep this runbook accessible during the migration window (Phase 26-30 execution on client Mac)
- After the verification runbook (RUNBOOK-05) passes completely, you can consider the migration stable
- Suggested timeline: keep `dotfiles-zsh` repository for 2 weeks after successful verification, then archive or delete
- If rollback is never needed (the happy path), this runbook served its purpose as a confidence safety net
- With Phase 31 complete, the v3.0 Client Migration milestone is finished. All 6 runbooks (RUNBOOK-01 through RUNBOOK-06) form a complete migration guide.

---

*Runbook created: 2026-02-16*
*Phase: 31-rollback-documentation*
