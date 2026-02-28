# Bootstrap Runbook

**Purpose:** Set up chezmoi infrastructure on the client Mac -- age encryption, source repo, and initial configuration

**Prerequisites:**
- Phase 26 audit complete (`~/migration-audit/` populated)
- Homebrew installed on client Mac (if not, install from https://brew.sh)
- Access to rbw (Bitwarden CLI) or web vault
- Age private key moved to `dotfiles/shared` folder in Bitwarden (item name: `age-private-key`). If it is still in `dotfiles/personal`, move it via the web vault or CLI before proceeding.
- Git access to the chezmoi source repository (`github.com/sleicht/chezmoi`)
- Terminal access on the client Mac

**Output:** A working chezmoi installation with age encryption and machine_type=client configuration

---

## Procedure 1: Set Up Age Encryption Key (BOOT-01)

**Objective:** Install the age encryption key needed to decrypt SSH keys and other secrets in the chezmoi source repository.

This is the critical bootstrap chain: the age key decrypts SSH keys and other secrets stored in the chezmoi source.

### Steps

1. Install age on the client Mac:
   ```bash
   brew install age
   ```

2. Understand the key architecture:
   - The chezmoi repo uses a **single age key pair** for encrypting secrets
   - The private key is stored at `~/.config/age/key-{machine_type}.txt` (per-machine filename, same key material)
   - The public key (recipient) is hardcoded in `.chezmoi.yaml.tmpl`: `age1hl7puvh5w5d49qgygxpj7q7zmc9gqyutqufk2p9x55mfm7ul742qg9vjn8`
   - The user needs the private key that matches this public key to decrypt secrets

3. Create the age key directory:
   ```bash
   mkdir -p ~/.config/age
   chmod 700 ~/.config/age
   ```

4. Retrieve the age private key and write it directly to the target path. There are two options:
   - **Option A: From Bitwarden via rbw** (preferred):
     ```bash
     # Install and configure rbw
     brew install rbw
     rbw config set email <your-email>
     rbw login
     rbw unlock
     rbw sync

     # Retrieve the age key directly to the target path
     rbw get age-private-key --folder dotfiles/shared > ~/.config/age/key-client.txt
     chmod 600 ~/.config/age/key-client.txt
     ```
   - **Option B: Copy from personal Mac** (simpler):
     ```bash
     # On personal Mac, print the key:
     cat ~/.config/age/key-personal.txt

     # On client Mac, paste the output into the target file:
     # It should start with "# created:" and "AGE-SECRET-KEY-..."
     cat > ~/.config/age/key-client.txt << 'EOF'
     # created: <timestamp>
     # public key: age1hl7puvh5w5d49qgygxpj7q7zmc9gqyutqufk2p9x55mfm7ul742qg9vjn8
     AGE-SECRET-KEY-<your-secret-key-here>
     EOF

     chmod 600 ~/.config/age/key-client.txt
     ```

5. Verify the key works:
   ```bash
   # Quick test: encrypt and decrypt a test string
   echo "test" | age -r age1hl7puvh5w5d49qgygxpj7q7zmc9gqyutqufk2p9x55mfm7ul742qg9vjn8 | age -d -i ~/.config/age/key-client.txt
   # Expected output: "test"
   ```

### Expected Output

The file `~/.config/age/key-client.txt` exists with 600 permissions. The encrypt/decrypt test prints "test".

### Troubleshooting

- If `age -d` fails with "no identity matched any of the recipients": the private key does not match the public key in the repo. Verify you copied the correct key.
- If the key is lost entirely: you must regenerate a key pair on the personal Mac, re-encrypt all `encrypted_*.age` files in the chezmoi source, update the `recipient` in `.chezmoi.yaml.tmpl`, and push. Then repeat this procedure with the new key.
- If rbw is not installed: `brew install rbw`, configure it with `rbw config set email <your-email>`, then `rbw login && rbw unlock && rbw sync`. Or just copy the key directly from your personal Mac.

### Output

`~/.config/age/key-client.txt` with correct permissions, verified with encrypt/decrypt round-trip.

---

## Procedure 2: Clone the Chezmoi Source Repository (BOOT-02)

**Objective:** Clone the dotfiles source repository to chezmoi's expected location on the client Mac.

### Steps

1. Install chezmoi on the client Mac:
   ```bash
   brew install chezmoi
   ```
   Verify installation:
   ```bash
   chezmoi --version
   ```

2. Clone the dotfiles source repository to chezmoi's expected location.

   **Note:** SSH keys are encrypted in the repo (chicken-and-egg), so use HTTPS for the initial clone:
   ```bash
   git clone https://github.com/sleicht/chezmoi.git ~/.local/share/chezmoi
   ```

   After chezmoi applies and deploys SSH keys (Phase 28), switch the remote to SSH:
   ```bash
   cd ~/.local/share/chezmoi
   git remote set-url origin git@github.com:sleicht/chezmoi.git
   ```

3. Verify the clone:
   ```bash
   ls ~/.local/share/chezmoi/.chezmoi.yaml.tmpl
   ls ~/.local/share/chezmoi/.chezmoidata.yaml
   ls ~/.local/share/chezmoi/private_dot_ssh/encrypted_private_id_rsa.age
   ```
   All three files should exist.

### Expected Output

The chezmoi source directory is populated at `~/.local/share/chezmoi/`.

### Troubleshooting

- If `~/.local/share/chezmoi` already exists (from a previous attempt): remove it first (`rm -rf ~/.local/share/chezmoi`) or move it aside
- If behind a corporate proxy: configure git proxy settings before cloning (`git config --global http.proxy http://proxy:port`)
- If SSH auth fails: use HTTPS clone first, switch to SSH after chezmoi deploys keys

### Output

Chezmoi source repo at `~/.local/share/chezmoi/` with all files present.

---

## Procedure 3: Run chezmoi init (BOOT-03)

**Objective:** Initialise chezmoi with client-specific configuration and verify age decryption works.

### Steps

1. Ensure rbw is installed and unlocked (chezmoi templates reference rbw for secrets):
   ```bash
   brew install rbw  # if not already installed
   rbw config set email <your-email>
   rbw login
   rbw unlock
   rbw sync
   ```

2. Run chezmoi init (this processes `.chezmoi.yaml.tmpl` and prompts for configuration):
   ```bash
   chezmoi init
   ```

   You will be prompted for:
   - **Machine type (client/personal/server):** Enter `client`
   - **Personal email address:** Enter your personal email
   - **Work email address:** Enter your work email (only prompted because machine_type=client)
   - **Computer name:** Enter the client Mac's hostname

   This creates `~/.config/chezmoi/chezmoi.yaml` with your configuration.

3. Verify the generated configuration:
   ```bash
   cat ~/.config/chezmoi/chezmoi.yaml
   ```

   Expected contents:
   ```yaml
   edit:
     apply: false
   git:
     autoCommit: true
     autoPush: false
   diff:
     pager: "less"
   encryption: "age"
   age:
     identity: "/Users/<you>/.config/age/key-client.txt"
     recipient: "age1hl7puvh5w5d49qgygxpj7q7zmc9gqyutqufk2p9x55mfm7ul742qg9vjn8"
   data:
     machine_type: "client"
     personal_email: "<your-personal-email>"
     work_email: "<your-work-email>"
     computer_name: "<hostname>"
     osid: "darwin"
   ```

   Check specifically:
   - `encryption: "age"` is set
   - `age.identity` points to `key-client.txt` (not `key-personal.txt`)
   - `machine_type` is `"client"`
   - `work_email` is present (only set for client machines)

4. Preview what chezmoi would deploy (DO NOT apply yet -- that is Phase 28):
   ```bash
   chezmoi diff | head -50
   ```
   This should show a large diff of files chezmoi would create/modify. If age decryption is working, you'll see decrypted SSH file contents in the diff (e.g., `.ssh/config`, `.ssh/id_rsa`). If decryption fails, chezmoi will error here — go back to Procedure 1.

### Expected Output

`~/.config/chezmoi/chezmoi.yaml` exists with correct machine_type=client and age encryption settings. `chezmoi diff` runs without decryption errors.

### Troubleshooting

- If `chezmoi init` fails with "age: decryption failed": the age key at `key-client.txt` does not match the recipient. Go back to Procedure 1.
- If `chezmoi init` fails with template errors referencing `rbw`: ensure rbw is installed, configured, and unlocked (`rbw unlock`).
- If prompts don't appear: chezmoi may have found an existing `chezmoi.yaml` from a previous run. Delete `~/.config/chezmoi/chezmoi.yaml` and rerun.
- If `chezmoi diff` fails with age decryption errors but `chezmoi init` succeeded: verify the age key file path and permissions (`ls -la ~/.config/age/key-client.txt` should show `-rw-------`).

### Output

`~/.config/chezmoi/chezmoi.yaml` with client configuration. `chezmoi diff` confirms age decryption works. Ready for Phase 28 (Migration).

---

## Summary

After completing all 3 procedures, you should have:
- `~/.config/age/key-client.txt` -- age encryption private key (600 permissions)
- `~/.local/share/chezmoi/` -- cloned chezmoi source repository
- `~/.config/chezmoi/chezmoi.yaml` -- generated chezmoi config with machine_type=client

### Verification Command

Run this command to verify all bootstrap requirements are met:

```bash
echo "=== Bootstrap Verification ==="

# Age key
if [ -f ~/.config/age/key-client.txt ]; then
  perms=$(stat -f "%Lp" ~/.config/age/key-client.txt 2>/dev/null || stat -c "%a" ~/.config/age/key-client.txt 2>/dev/null)
  echo "✓ Age key exists (permissions: $perms)"
else
  echo "✗ MISSING: ~/.config/age/key-client.txt"
fi

# Chezmoi source
if [ -f ~/.local/share/chezmoi/.chezmoi.yaml.tmpl ]; then
  echo "✓ Chezmoi source repo cloned"
else
  echo "✗ MISSING: ~/.local/share/chezmoi/"
fi

# Chezmoi config
if [ -f ~/.config/chezmoi/chezmoi.yaml ]; then
  machine_type=$(grep 'machine_type' ~/.config/chezmoi/chezmoi.yaml | awk '{print $2}' | tr -d '"')
  echo "✓ Chezmoi config exists (machine_type: $machine_type)"
else
  echo "✗ MISSING: ~/.config/chezmoi/chezmoi.yaml"
fi

# Age decryption test (chezmoi diff must be able to decrypt .age files)
if chezmoi diff >/dev/null 2>&1; then
  echo "✓ Age decryption working (chezmoi diff succeeded)"
else
  echo "✗ Age decryption failed (chezmoi diff errored)"
fi
```

---

## Next Steps

- **Do NOT run `chezmoi apply` yet** -- Phase 28 covers safe Dotbot symlink removal first
- If using HTTPS clone, switch to SSH after Phase 28 deploys SSH keys
- Proceed to **Phase 28: Migration** to safely remove Dotbot symlinks and run `chezmoi apply`

---

*Bootstrap runbook created: 2026-02-15*
