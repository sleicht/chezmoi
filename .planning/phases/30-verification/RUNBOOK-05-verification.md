# Verification Runbook

## Purpose

Confirm the Dotbot-to-chezmoi migration was successful by systematically verifying shell functionality, git workflows, tool availability, and running the automated smoke test.

This is the acceptance test for the entire v3.0 client migration. If all procedures pass, the migration is complete and the client Mac is fully running on the chezmoi-managed dotfiles stack.

## Prerequisites

- Phase 28 migration complete (all chezmoi-managed files deployed)
- Phase 29 reintegration complete (local customisations merged back)
- `chezmoi diff --exclude=scripts` produces empty output (fully in sync)
- Terminal access on the client Mac
- Approximately 15-20 minutes to complete all procedures

## Output

Verification report confirming all subsystems work correctly, or a list of issues to debug.

---

## Procedure 1: Verify Shell Functionality (VERIF-01)

### Objective

Confirm that the ZSH shell starts correctly with aliases, prompt rendering, and deferred plugin loading all working.

### Context

The chezmoi-managed shell configuration uses a modular architecture: `dot_zshrc.tmpl` loads Sheldon (plugin manager), which sources `~/.zsh.d/*.zsh` modules. Plugins are split into sync (loaded immediately) and deferred (loaded via `zsh-defer` after prompt renders). The prompt is rendered by oh-my-posh. Aliases are defined in `~/.zsh.d/aliases.zsh`. If any of these fail, the shell may start but be missing functionality.

### Steps

**1. Start a fresh shell and check for startup errors:**

```bash
# Start a new shell (watch for error messages)
exec zsh
```

**Expected:** Clean startup with no error messages. Prompt renders correctly (styled, not a bare `%` or `$`).

**2. Verify shell startup time is within budget:**

```bash
echo "Startup time: ${LAST_SHELL_STARTUP_MS}ms"
# Target: under 300ms
```

If >300ms, a warning should have appeared automatically. This is not a blocker but worth noting.

**3. Check that aliases are loaded:**

```bash
# List defined aliases (should show entries from aliases.zsh)
alias | head -20

# Test a specific alias (adapt to your actual aliases)
# Example: if you have ll="lsd -la", try:
type ll
```

**4. Verify the prompt engine is running:**

```bash
# Check oh-my-posh is the active prompt
echo $PROMPT | head -c 50

# Or check oh-my-posh is available:
(( $+commands[oh-my-posh] )) && echo "oh-my-posh: available" || echo "oh-my-posh: MISSING"
```

**5. Verify deferred plugins loaded:**

```bash
# zsh-autosuggestions (sync -- should be loaded immediately)
zle -l 2>/dev/null | grep -q autosuggest && echo "autosuggestions: loaded" || echo "autosuggestions: NOT LOADED"

# zsh-syntax-highlighting (deferred -- may need a moment)
# Type a command (e.g., "ls") and check if it highlights in green (valid) or red (invalid)
# This is a visual check -- syntax highlighting colours commands as you type

# Completions initialised
(( $+_comps )) && echo "completions: initialised" || echo "completions: NOT initialised"
```

**6. Verify Sheldon plugin manager is operational:**

```bash
sheldon lock --update 2>/dev/null && echo "sheldon: OK" || echo "sheldon: ERROR"
```

This refreshes the plugin lock file. If sheldon is misconfigured, this will fail.

**7. Verify the Atuin history keybinding:**

```bash
bindkey 2>/dev/null | grep -q atuin && echo "atuin keybinding: configured" || echo "atuin keybinding: MISSING"
```

Press Ctrl+R to confirm Atuin's interactive history search opens (visual check).

### Expected Output

Shell starts cleanly, prompt renders, aliases resolve, both sync and deferred plugins load, completions work, Atuin keybinding active.

### Troubleshooting

- **If the shell shows errors on startup:** Check `~/.zshrc` rendering with `chezmoi cat ~/.zshrc` and compare to the deployed version. Template rendering issues often cause syntax errors.
- **If aliases are missing:** Verify `~/.zsh.d/aliases.zsh` exists and is sourced. Check `sheldon source` output for the aliases module.
- **If oh-my-posh prompt doesn't render:** Verify `(( $+commands[oh-my-posh] ))` returns true. If missing, check `brew list | grep oh-my-posh` and reinstall if needed.
- **If deferred plugins don't load:** Check that `zsh-defer` is configured in sheldon. Run `sheldon source | grep defer` to verify the deferred loading mechanism is in place.
- **If startup time exceeds 300ms:** Profile with `ZSH_PROFILE_STARTUP=1 zsh -i -c exit` to identify the slow module. This is not a migration failure but may indicate a configuration issue.

### Output

Shell functionality verified. All interactive features (aliases, prompt, plugins, completions, history search) working.

---

## Procedure 2: Verify Git Workflows (VERIF-02)

### Objective

Confirm that git operations (commit, push), mise-powered tasks, and git hooks all function correctly.

### Context

The chezmoi-managed setup includes:
- `~/.gitconfig` (main git config, may be templated for machine_type)
- `private_dot_gitconfig_local.tmpl` (machine-specific overrides: name, email, signing key)
- mise task runner with git workflow tasks (`mise run git:*`)
- Pre-commit hooks (gitleaks secret scanning)
- The chezmoi repo itself should be using SSH remote after Phase 28

### Steps

**1. Verify git identity is configured correctly:**

```bash
echo "Git user: $(git config user.name)"
echo "Git email: $(git config user.email)"
```

**Expected:** Your work identity (name and work email) should be set.

**2. Verify git can communicate with GitHub over SSH:**

```bash
ssh -T git@github.com 2>&1 || true
# Expected: "Hi <username>! You've successfully authenticated..."
```

If this fails, SSH keys may not have deployed correctly (see Troubleshooting).

**3. Test a git commit in the chezmoi repo (non-destructive):**

```bash
cd ~/.local/share/chezmoi

# Verify the remote is SSH (set during Phase 28)
git remote get-url origin
# Expected: git@github.com:sleicht/chezmoi.git

# Create a test file, commit, then revert
echo "migration-verification-test" > /tmp/verify-git-test.txt
cp /tmp/verify-git-test.txt .git-test-file
git add .git-test-file
git commit -m "test: verify git commit works post-migration"
# Expected: commit succeeds, pre-commit hooks run (gitleaks scan)

# Clean up the test commit
git reset --soft HEAD~1
git restore --staged .git-test-file
rm .git-test-file
```

**4. Verify pre-commit hooks are active:**

```bash
cd ~/.local/share/chezmoi
ls -la .git/hooks/pre-commit
# Expected: hook exists (symlink or file)

# Run hooks manually to verify
pre-commit run --all-files 2>&1 | tail -5
# Expected: all hooks pass (gitleaks, YAML validation, whitespace)
```

**5. Test mise task runner:**

```bash
# List available tasks
mise tasks ls 2>/dev/null | head -10
# Expected: should show dotfiles:* and git:* tasks

# Run a safe read-only task
mise run dotfiles:diff 2>/dev/null
# Expected: shows chezmoi diff output (should be empty if in sync)
```

**6. Verify git push works (optional -- only if you want to push the test):**

```bash
# Only run this if you confirmed SSH access in step 2
cd ~/.local/share/chezmoi
git fetch origin
# Expected: fetches without error (confirms SSH push/pull works)
```

### Expected Output

Git identity correct, SSH authentication works, commits succeed with hooks running, mise tasks available and functional, fetch/push over SSH works.

### Troubleshooting

- **If `ssh -T git@github.com` fails:** Check `~/.ssh/config` for a GitHub host entry, verify `~/.ssh/id_rsa` exists with 600 permissions, try `ssh -vT git@github.com` for debug output.
- **If git commit fails with "author identity unknown":** Run `git config --list --show-origin | grep user` to find where identity should be set. Check `~/.gitconfig` and `~/.gitconfig_local`.
- **If pre-commit hooks fail:** Ensure `pre-commit` is installed (`brew list | grep pre-commit`). Reinstall hooks with `pre-commit install --hook-type pre-commit --hook-type pre-push`.
- **If mise tasks are missing:** Verify `~/.config/mise/tasks/` directory exists and contains task files. Run `chezmoi managed | grep mise/tasks` to confirm chezmoi deployed them.
- **If git push is rejected:** This is likely an authentication issue, not a migration issue. Verify SSH agent has the key loaded: `ssh-add -l`.

### Output

Git workflows verified. Commits, hooks, SSH access, and mise tasks all functional.

---

## Procedure 3: Verify Tool Availability (VERIF-03)

### Objective

Confirm that mise runtimes, Homebrew packages, and encryption keys are all available and functional.

### Context

The chezmoi-managed setup relies on:
- mise for runtime version management (node, python, go, rust, java, ruby, terraform)
- Homebrew for CLI tools and applications (managed via `dot_Brewfile.tmpl`)
- age encryption for sensitive files (SSH keys, etc.) with the identity key at `~/.config/age/key-client.txt`
- Bitwarden CLI for secret templating (used during `chezmoi apply` for secrets)

### Steps

**1. Verify mise is available and runtimes are installed:**

```bash
# Check mise itself
mise --version
# Expected: mise version number

# List installed runtimes
mise ls
# Expected: node, python, go, and potentially others with version numbers

# Test a runtime
node --version
python3 --version
go version
```

If any runtime is missing, `mise install` will install it from `.mise.toml`.

**2. Verify critical Homebrew packages are installed:**

```bash
# Check core tools used by the dotfiles stack
for tool in chezmoi mise oh-my-posh sheldon atuin zoxide fzf bat lsd git pre-commit gitleaks age; do
  if command -v "$tool" &>/dev/null; then
    echo "OK: $tool ($(command -v "$tool"))"
  else
    echo "MISSING: $tool"
  fi
done
```

If any are missing, they should be installable via `brew bundle --file=~/.Brewfile`.

**3. Verify age encryption key is in place:**

```bash
# Check the age identity key exists with correct permissions
if [ -f ~/.config/age/key-client.txt ]; then
  perms=$(stat -f '%Lp' ~/.config/age/key-client.txt 2>/dev/null)
  echo "Age key: exists (permissions: $perms)"
  # Permissions should be 600
  if [ "$perms" = "600" ]; then
    echo "  Permissions: OK"
  else
    echo "  Permissions: WRONG (should be 600)"
  fi
else
  echo "Age key: MISSING at ~/.config/age/key-client.txt"
fi
```

**4. Verify chezmoi can decrypt encrypted files:**

```bash
# List encrypted files managed by chezmoi
chezmoi managed | grep -i encrypt || echo "(no encrypted files in managed list)"

# Test decryption by re-applying an encrypted file (non-destructive)
chezmoi cat ~/.ssh/id_rsa > /dev/null 2>&1 && echo "Decryption: OK" || echo "Decryption: FAILED"
```

**5. Verify SSH key is functional:**

```bash
# Check SSH key exists and has correct permissions
ls -la ~/.ssh/id_rsa 2>/dev/null
# Expected: -rw------- (600 permissions)

# Check SSH agent has the key loaded (or can load it)
ssh-add -l 2>/dev/null || ssh-add ~/.ssh/id_rsa 2>/dev/null
```

**6. Verify Homebrew is healthy:**

```bash
brew doctor 2>&1 | head -10
# Expected: "Your system is ready to brew." or minor warnings
```

### Expected Output

mise runtimes respond, all critical Homebrew packages available, age key present with correct permissions, chezmoi decryption works, SSH key functional.

### Troubleshooting

- **If mise runtimes are missing:** Run `mise install` to install from `.mise.toml`. If `.mise.toml` is missing, check `chezmoi managed | grep mise`.
- **If Homebrew packages are missing:** Run `brew bundle --file=~/.Brewfile` to install from the Brewfile. If the Brewfile is empty or missing, check `chezmoi cat ~/.Brewfile`.
- **If age key is missing:** Revisit Phase 27 (Bootstrap) to set up the age key. The key must be manually provisioned from Bitwarden.
- **If decryption fails:** Verify `~/.config/chezmoi/chezmoi.yaml` has the correct `encryption: age` and `age.identity` settings. Run `chezmoi doctor` for diagnostics.
- **If SSH key permissions are wrong:** Run `chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub`.
- **If `brew doctor` reports issues:** These are usually non-critical warnings. Focus on errors, not warnings.

### Output

Tool availability verified. All runtimes, packages, and encryption infrastructure functional.

---

## Procedure 4: Run Smoke Test (VERIF-04)

### Objective

Run the automated 13-check smoke test script and verify all checks pass.

### Context

The smoke test script (`scripts/zsh-smoke-test`) was created in Phase 22 (v2.0 Performance milestone) and wraps 13 automated checks covering: oh-my-posh availability, prompt configuration, mise availability, completion system, Atuin keybinding, 5 critical tools (git, zoxide, fzf, bat, lsd), zsh-autosuggestions loaded, zsh-syntax-highlighting configured, and startup monitoring active. It can be run via `mise run dotfiles:smoke-test` or directly.

### Steps

**1. Run the smoke test via the mise task runner:**

```bash
mise run dotfiles:smoke-test
```

Or run directly if mise tasks are not available:

```bash
~/.local/share/chezmoi/scripts/zsh-smoke-test
```

**2. Review the output. Expected:**

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

All checks passed
```

**3. If any checks fail, note which ones failed and refer to the troubleshooting section. Each failure maps to a specific subsystem:**

- **Checks 1-2 (oh-my-posh, prompt):** Prompt engine issue -- see Procedure 1 troubleshooting
- **Check 3 (mise):** Runtime manager issue -- see Procedure 3 troubleshooting
- **Check 4 (completions):** Completion system not initialised -- check `compinit` in zshrc
- **Check 5 (Atuin):** History search keybinding missing -- check Atuin installation and config
- **Checks 6-10 (git, zoxide, fzf, bat, lsd):** Missing CLI tool -- install via `brew install <tool>`
- **Check 11 (autosuggestions):** Plugin not loaded -- check sheldon config
- **Check 12 (syntax-highlighting):** Plugin not configured -- check `~/.config/sheldon/plugins.toml`
- **Check 13 (startup monitoring):** Performance monitoring inactive -- check `LAST_SHELL_STARTUP_MS` in zshrc

**4. If all 13 checks pass, the migration is verified complete.**

### Expected Output

13/13 checks pass. Exit code 0.

### Troubleshooting

- **If the smoke test script is not found:** Verify `~/.local/share/chezmoi/scripts/zsh-smoke-test` exists and is executable. If missing, run `chezmoi apply` to deploy it.
- **If the mise task wrapper is not found:** Verify `~/.config/mise/tasks/dotfiles/smoke-test` exists. Run `chezmoi managed | grep smoke` to confirm.
- **If checks fail that passed in Procedures 1-3:** The smoke test runs in a subshell which may not have the same environment. Try running in an interactive shell: `zsh -i -c '~/.local/share/chezmoi/scripts/zsh-smoke-test'`.
- **If `LAST_SHELL_STARTUP_MS` check fails:** This variable is set at the end of `.zshrc`. If the shell startup was interrupted by an error, this variable won't be set. Fix the upstream error first.

### Output

Smoke test passes 13/13 checks. Migration verification complete.

---

## Summary

After completing all 4 procedures, you should have:

- **Shell functionality confirmed:** Aliases, prompt, plugins, completions, and history search all working
- **Git workflows confirmed:** Commits succeed, hooks run, SSH access works, mise tasks functional
- **Tool availability confirmed:** mise runtimes respond, Homebrew packages present, age encryption works
- **Smoke test passes all 13 checks**

If all procedures pass, the v3.0 client migration is complete. The client Mac is now fully running on the chezmoi-managed dotfiles stack.

---

## Verification Command (Aggregate)

For a single-pass check of all critical subsystems, run:

```bash
echo "=== Migration Verification Summary ==="
echo ""

# 1. chezmoi in sync
if chezmoi diff --exclude=scripts 2>/dev/null | head -1 | grep -q '^'; then
  echo "[FAIL] chezmoi has remaining differences"
else
  echo "[PASS] chezmoi fully in sync"
fi

# 2. Shell starts cleanly
if zsh -i -c 'exit 0' 2>/dev/null; then
  echo "[PASS] Shell starts without errors"
else
  echo "[FAIL] Shell startup has errors"
fi

# 3. Git identity
if git config user.email &>/dev/null; then
  echo "[PASS] Git identity configured ($(git config user.email))"
else
  echo "[FAIL] Git identity not configured"
fi

# 4. SSH access
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "[PASS] SSH authentication to GitHub"
else
  echo "[WARN] SSH authentication to GitHub (may need key agent)"
fi

# 5. mise runtimes
if mise ls 2>/dev/null | grep -q "node"; then
  echo "[PASS] mise runtimes installed"
else
  echo "[FAIL] mise runtimes missing"
fi

# 6. Age key
if [ -f ~/.config/age/key-client.txt ] && [ "$(stat -f '%Lp' ~/.config/age/key-client.txt)" = "600" ]; then
  echo "[PASS] Age encryption key present (600 permissions)"
else
  echo "[FAIL] Age encryption key missing or wrong permissions"
fi

# 7. Smoke test
if ~/.local/share/chezmoi/scripts/zsh-smoke-test 2>/dev/null; then
  echo "[PASS] Smoke test: 13/13 checks passed"
else
  echo "[FAIL] Smoke test: some checks failed (run manually for details)"
fi

echo ""
echo "=== End Verification ==="
```

---

## Next Steps

- **If all checks pass:** The v3.0 client migration is COMPLETE. Proceed to Phase 31 (Rollback Documentation) for safety net procedures.
- **If some checks fail:** Debug the failures using the troubleshooting sections in each procedure. Most failures are configuration issues, not fundamental migration problems.
- **Archive migration audit directory:** The `~/migration-audit/` directory can be archived or deleted once you're confident the migration is stable. Keep it for a week or two as a safety net.
- **Push chezmoi source changes:** Consider pushing any chezmoi source changes made during verification:

  ```bash
  cd ~/.local/share/chezmoi && git push
  ```
