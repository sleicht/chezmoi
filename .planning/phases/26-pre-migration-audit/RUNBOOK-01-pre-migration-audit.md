# Pre-Migration Audit Runbook

## Purpose

Capture local state on the client Mac before switching from Dotbot to chezmoi. This runbook ensures no valuable configuration, scripts, or environment variables are lost during the migration.

## Prerequisites

- Access to the client Mac (work machine currently running dotfiles-zsh with Dotbot)
- The frozen `dotfiles-zsh` repository still present on the client Mac
- Terminal access with standard Unix tools (`find`, `grep`, `git`, `diff`)
- Approximately 15-20 minutes to complete all procedures

## Output

An audit report saved to `~/migration-audit/` containing:
- List of all Dotbot-managed symlinks
- Inventory of custom scripts not tracked in any repository
- Machine-specific environment variables unique to the client Mac
- Diffs showing configuration drift from the frozen repository

## Procedure 1: List Dotbot Symlinks (AUDIT-01)

**Objective:** Enumerate all symlinks created by Dotbot to understand what's currently being managed.

### Steps

1. Create the output directory:
   ```bash
   mkdir -p ~/migration-audit
   ```

2. Locate the Dotbot configuration file and review the symlink mappings:
   ```bash
   # Verify the actual path to your dotfiles repo
   # Common locations: ~/dotfiles-zsh, ~/.dotfiles, ~/dotfiles
   cat ~/dotfiles-zsh/install.conf.yaml
   ```

   **Expected output:** YAML configuration showing the `link:` section with source→target mappings.

3. Find all symlinks in your home directory that point into the dotfiles repository:
   ```bash
   # Find symlinks in top-level directories that point to dotfiles repo
   find ~ -maxdepth 3 -type l -exec sh -c 'target=$(readlink -f "$1" 2>/dev/null); echo "$target" | grep -qi dotfiles && echo "$1 -> $target"' _ {} \; 2>/dev/null | sort > ~/migration-audit/dotbot-symlinks.txt
   ```

   **Expected output:** Lines like `~/.zshrc -> ~/dotfiles-zsh/zshrc`

4. Check for symlinks in common configuration directories:
   ```bash
   # .config directory
   find ~/.config -maxdepth 2 -type l -exec sh -c 'echo "$1 -> $(readlink -f "$1" 2>/dev/null)"' _ {} \; 2>/dev/null >> ~/migration-audit/dotbot-symlinks.txt

   # .ssh directory
   find ~/.ssh -type l -exec sh -c 'echo "$1 -> $(readlink -f "$1" 2>/dev/null)"' _ {} \; 2>/dev/null >> ~/migration-audit/dotbot-symlinks.txt

   # Sort and deduplicate
   sort -u ~/migration-audit/dotbot-symlinks.txt -o ~/migration-audit/dotbot-symlinks.txt
   ```

5. (Optional) Cross-reference with chezmoi's managed file list:
   ```bash
   # If chezmoi is already installed on this Mac:
   chezmoi managed --exclude=dirs 2>/dev/null | sort > ~/migration-audit/chezmoi-managed.txt

   # If chezmoi is not installed here, you can generate this list on your personal Mac
   # and copy it over for comparison, or skip this step and do it in Phase 27
   ```

6. Review the symlink inventory:
   ```bash
   wc -l ~/migration-audit/dotbot-symlinks.txt
   cat ~/migration-audit/dotbot-symlinks.txt
   ```

**Troubleshooting:**
- If `find` is slow, reduce `-maxdepth` or target specific directories
- If `readlink -f` fails on macOS, ensure you're using GNU coreutils or use `greadlink -f` (install via `brew install coreutils`)
- If the dotfiles repo path differs from `~/dotfiles-zsh`, adjust all commands accordingly

**Output:** `~/migration-audit/dotbot-symlinks.txt` – one symlink per line with format `symlink -> target`

---

## Procedure 2: Identify Custom Scripts and Bins (AUDIT-02)

**Objective:** Find scripts you've placed locally that are NOT tracked in either the dotfiles-zsh or chezmoi repositories.

### Steps

1. List all files in common bin directories:
   ```bash
   # ~/bin
   if [ -d ~/bin ]; then
     ls -la ~/bin/ > ~/migration-audit/custom-bins.txt
   else
     echo "~/bin does not exist" > ~/migration-audit/custom-bins.txt
   fi

   # ~/.local/bin
   if [ -d ~/.local/bin ]; then
     echo -e "\n--- ~/.local/bin ---" >> ~/migration-audit/custom-bins.txt
     ls -la ~/.local/bin/ >> ~/migration-audit/custom-bins.txt
   else
     echo "~/.local/bin does not exist" >> ~/migration-audit/custom-bins.txt
   fi
   ```

2. Identify scripts that are NOT in the dotfiles-zsh repository:
   ```bash
   # Check ~/bin contents against dotfiles repo
   > ~/migration-audit/untracked-scripts.txt  # Clear/create file

   for dir in ~/bin ~/.local/bin; do
     if [ -d "$dir" ]; then
       for f in "$dir"/*; do
         if [ -f "$f" ]; then
           name=$(basename "$f")
           # Check common locations in dotfiles-zsh
           if [ ! -e ~/dotfiles-zsh/bin/"$name" ] && \
              [ ! -e ~/dotfiles-zsh/scripts/"$name" ] && \
              [ ! -e ~/dotfiles-zsh/.local/bin/"$name" ]; then
             echo "CUSTOM (not in dotfiles-zsh): $f" >> ~/migration-audit/untracked-scripts.txt
           fi
         fi
       done
     fi
   done
   ```

3. (Optional) Cross-reference with chezmoi source:
   ```bash
   # On your personal Mac where chezmoi is set up:
   chezmoi managed | grep -E '(bin/|\.local/bin/)' > ~/migration-audit/chezmoi-bins.txt

   # Copy this file to the client Mac, then compare:
   # comm -23 <(sort ~/migration-audit/untracked-scripts.txt) <(sort ~/migration-audit/chezmoi-bins.txt)
   ```

4. Review each untracked script and classify:
   ```bash
   cat ~/migration-audit/untracked-scripts.txt
   ```

   For each script, decide:
   - **Preserve:** Important tool to add to chezmoi
   - **Keep local:** Machine-specific utility that shouldn't be in dotfiles
   - **Discard:** Old/obsolete script safe to remove

**Expected output:** List of scripts needing triage. Even if empty, this confirms nothing will be lost.

**Troubleshooting:**
- If you have other bin locations (e.g., `~/scripts`, `~/.bin`), add them to the loop
- Symlinked scripts will appear in the listing but their targets should be checked separately

**Output:** `~/migration-audit/untracked-scripts.txt` – files needing triage before migration

---

## Procedure 3: Capture Machine-Specific Environment Variables (AUDIT-03)

**Objective:** Capture environment variables unique to the client Mac, especially company-specific configurations that won't be in your personal dotfiles.

### Steps

1. Capture the full environment in an interactive shell:
   ```bash
   # Start a fresh interactive shell to load all configs
   zsh -i -c 'env | sort' > ~/migration-audit/client-env-full.txt
   ```

2. Capture shell-defined exports from configuration files:
   ```bash
   # Search for export statements in shell configs
   grep -rn 'export ' \
     ~/.zshrc \
     ~/.zshenv \
     ~/.profile \
     ~/.zsh.d/ \
     ~/dotfiles-zsh/ \
     2>/dev/null | sort -u > ~/migration-audit/client-exports.txt
   ```

3. Capture exports from private/local override files:
   ```bash
   # These files won't be in any repository
   grep -rn 'export ' \
     ~/.zsh.d.private/ \
     ~/.zshrc.local \
     ~/.profile.local \
     ~/.config/zsh/local/ \
     2>/dev/null | sort > ~/migration-audit/client-private-exports.txt

   # If file is empty or doesn't exist, that's fine
   [ -s ~/migration-audit/client-private-exports.txt ] || echo "No private export files found" > ~/migration-audit/client-private-exports.txt
   ```

4. (Optional) Compare against your personal Mac environment:
   ```bash
   # On your personal Mac:
   env | sort > /tmp/personal-env.txt

   # Copy to client Mac, then identify unique variables:
   diff ~/migration-audit/client-env-full.txt /tmp/personal-env.txt | grep '^<' | sed 's/^< //' > ~/migration-audit/client-unique-env.txt
   ```

5. Review key variables that typically differ on work machines:
   ```bash
   # Extract specific variable categories
   grep -E '(PROXY|HTTP_PROXY|HTTPS_PROXY|NO_PROXY|JAVA_HOME|ANDROID_HOME|FLUTTER_HOME|_TOKEN|_KEY|_SECRET|_API)' \
     ~/migration-audit/client-env-full.txt \
     > ~/migration-audit/client-critical-vars.txt
   ```

   **Key variables to look for:**
   - `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` – corporate proxy settings
   - `JAVA_HOME`, `ANDROID_HOME`, `FLUTTER_HOME` – SDK paths
   - Company-specific variables (VPN configs, internal tool paths, build system vars)
   - `*_TOKEN`, `*_KEY`, `*_SECRET` – note these exist but **DO NOT save the actual values in the audit**

6. Review the collected environment data:
   ```bash
   echo "=== Total environment variables ==="
   wc -l ~/migration-audit/client-env-full.txt

   echo -e "\n=== Critical variables found ==="
   cat ~/migration-audit/client-critical-vars.txt
   ```

**Security note:** If any files contain sensitive tokens or keys, ensure `~/migration-audit/` is not committed to git or shared publicly. The goal is to identify WHICH variables exist, not necessarily preserve their values (secrets should be managed separately via Bitwarden, 1Password, etc.).

**Troubleshooting:**
- If certain paths don't exist (e.g., `.zsh.d.private`), that's expected – the grep will skip them
- If you use other shell config locations (e.g., `.envrc` files via direnv), add those paths to the search

**Output:** Multiple files capturing environment variable state:
- `client-env-full.txt` – complete environment
- `client-exports.txt` – export statements from configs
- `client-private-exports.txt` – exports from private override files
- `client-unique-env.txt` – variables unique to client Mac (if comparison performed)
- `client-critical-vars.txt` – important variables to migrate

---

## Procedure 4: Diff Drifted Configs (AUDIT-04)

**Objective:** Find configuration files that have been edited locally and drifted from the frozen repository version.

### Steps

1. Check git status in the dotfiles-zsh repository:
   ```bash
   cd ~/dotfiles-zsh  # or your actual repo path

   # Capture git status
   git status > ~/migration-audit/dotfiles-drift-status.txt

   # Capture full diff of uncommitted changes
   git diff > ~/migration-audit/dotfiles-drift-diff.txt

   # Also capture diff stat for overview
   git diff --stat >> ~/migration-audit/dotfiles-drift-status.txt
   ```

   **Expected output:** If the repository is clean, the diff files will be empty. If you've made local edits, they'll appear here.

2. Check for staged but uncommitted changes:
   ```bash
   git diff --cached >> ~/migration-audit/dotfiles-drift-diff.txt
   ```

3. Identify files that exist as regular files instead of symlinks:
   ```bash
   # These are files that should be Dotbot symlinks but have been replaced with copies
   > ~/migration-audit/non-symlink-overrides.txt

   # Check common dotfiles
   for target in ~/.gitconfig ~/.zshrc ~/.zshenv ~/.profile ~/.vimrc ~/.tmux.conf; do
     if [ -f "$target" ] && [ ! -L "$target" ]; then
       echo "REAL FILE (not symlink): $target" >> ~/migration-audit/non-symlink-overrides.txt
       # Show how it differs from the repo version
       repo_path="$HOME/dotfiles-zsh/$(basename "$target" | sed 's/^\.//')"
       if [ -f "$repo_path" ]; then
         echo "  Differs from: $repo_path" >> ~/migration-audit/non-symlink-overrides.txt
         diff -u "$repo_path" "$target" >> ~/migration-audit/non-symlink-overrides.txt
       fi
     fi
   done

   # If no overrides found, note that
   [ -s ~/migration-audit/non-symlink-overrides.txt ] || echo "No non-symlink overrides found" > ~/migration-audit/non-symlink-overrides.txt
   ```

4. Check for untracked files in the repository:
   ```bash
   cd ~/dotfiles-zsh
   git ls-files --others --exclude-standard > ~/migration-audit/dotfiles-untracked.txt
   ```

5. Review the drift and categorise changes:
   ```bash
   # View drift summary
   echo "=== Modified files in repository ==="
   cd ~/dotfiles-zsh
   git status --short

   echo -e "\n=== Diff statistics ==="
   git diff --stat

   echo -e "\n=== Non-symlink overrides ==="
   cat ~/migration-audit/non-symlink-overrides.txt
   ```

   For each changed file, decide:
   - **Valuable edit:** Note for reintegration in Phase 29 (client-specific configs)
   - **Stale/irrelevant:** Safe to discard, will use current chezmoi version
   - **Unknown:** Flag for manual review during migration

6. Document your decisions:
   ```bash
   # Create a triage file for review
   echo "# Drift Triage" > ~/migration-audit/drift-triage.md
   echo "" >> ~/migration-audit/drift-triage.md
   echo "Review each modified file and mark action:" >> ~/migration-audit/drift-triage.md
   echo "" >> ~/migration-audit/drift-triage.md

   cd ~/dotfiles-zsh
   git status --short | while read status file; do
     echo "- [ ] \`$file\` ($status) – Action: [keep/discard/review]" >> ~/migration-audit/drift-triage.md
   done
   ```

**Troubleshooting:**
- If the repository is in a detached HEAD state or has no git history, adjust the git commands accordingly
- If you've made commits locally, also run `git log origin/main..HEAD` to see unpushed commits
- If the repo is dirty and you're unsure about changes, create a backup: `tar czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz ~/dotfiles-zsh`

**Output:**
- `dotfiles-drift-status.txt` – git status and diff statistics
- `dotfiles-drift-diff.txt` – full diff of uncommitted changes
- `non-symlink-overrides.txt` – files that should be symlinks but aren't
- `dotfiles-untracked.txt` – untracked files in the repository
- `drift-triage.md` – checklist for reviewing each change

---

## Summary

After completing all 4 procedures, you should have these audit files in `~/migration-audit/`:

**Procedure 1 (Symlinks):**
- `dotbot-symlinks.txt` – all Dotbot-managed symlinks
- `chezmoi-managed.txt` – (optional) chezmoi-managed files for comparison

**Procedure 2 (Scripts):**
- `custom-bins.txt` – listing of ~/bin and ~/.local/bin contents
- `untracked-scripts.txt` – scripts not in dotfiles-zsh repo
- `chezmoi-bins.txt` – (optional) chezmoi-managed bin files for comparison

**Procedure 3 (Environment):**
- `client-env-full.txt` – complete environment variables
- `client-exports.txt` – export statements from config files
- `client-private-exports.txt` – exports from private override files
- `client-unique-env.txt` – (optional) variables unique to client Mac
- `client-critical-vars.txt` – important variables (proxies, SDKs, tokens)

**Procedure 4 (Drift):**
- `dotfiles-drift-status.txt` – git status and diff statistics
- `dotfiles-drift-diff.txt` – full diff of uncommitted changes
- `non-symlink-overrides.txt` – non-symlink config file overrides
- `dotfiles-untracked.txt` – untracked files in repository
- `drift-triage.md` – triage checklist for review

### Verification

Run this to confirm all expected files are present:

```bash
echo "=== Audit Completion Check ==="
for file in \
  dotbot-symlinks.txt \
  custom-bins.txt \
  untracked-scripts.txt \
  client-env-full.txt \
  client-exports.txt \
  client-private-exports.txt \
  client-critical-vars.txt \
  dotfiles-drift-status.txt \
  dotfiles-drift-diff.txt \
  non-symlink-overrides.txt \
  dotfiles-untracked.txt \
  drift-triage.md; do
  if [ -f ~/migration-audit/"$file" ]; then
    size=$(wc -l < ~/migration-audit/"$file" | tr -d ' ')
    echo "✓ $file ($size lines)"
  else
    echo "✗ MISSING: $file"
  fi
done
```

### Security Reminder

Before proceeding to Phase 27:
1. Review `client-critical-vars.txt` and ensure no secrets are exposed
2. Do NOT commit `~/migration-audit/` to any git repository
3. Consider encrypting the audit directory if it contains sensitive paths: `tar czf - ~/migration-audit | gpg -c > ~/migration-audit.tar.gz.gpg`

### Next Steps

Once the audit is complete and you've reviewed the outputs:
1. Keep the `~/migration-audit/` directory for reference during migration
2. Proceed to **Phase 27: Bootstrap** runbook to initialise chezmoi on the client Mac
3. You'll reference these audit files in **Phase 29: Client-Specific Configs** when integrating unique client Mac settings

The audit ensures you have a complete snapshot of the client Mac's current state before making any changes.
