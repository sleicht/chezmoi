# SSH Config Migration — Per-Machine-Type Split

## Background

SSH config was refactored from a single encrypted file (`encrypted_private_config.age`) to three machine-type-specific files:

- `config_personal` — personal hosts
- `config_client` — work/client hosts
- `config_server` — server hosts

A template wrapper (`~/.ssh/config`) uses SSH's `Include` directive to load the correct file based on `machine_type`.

## Migration Steps

On each machine that already has chezmoi set up:

```bash
# 1. Back up current SSH config
cp ~/.ssh/config ~/.ssh/config.bak

# 2. Pull latest chezmoi source and apply
chezmoi update

# 3. Move old config content into the machine-specific file
chezmoi edit ~/.ssh/config_client   # or config_server / config_personal

# 4. Paste content from ~/.ssh/config.bak into the editor, save, exit

# 5. Verify SSH still works
ssh -T <any-host-from-your-config>

# 6. Clean up
rm ~/.ssh/config.bak
```

## What Happens During Apply

After `chezmoi update`:

- `~/.ssh/config` becomes a one-line file: `Include ~/.ssh/config_<machine_type>`
- `~/.ssh/config_<machine_type>` is decrypted from the matching `.age` file (empty on first deploy for client/server)
- Non-matching `config_*` files are excluded by `.chezmoiignore` and never deployed

## Notes

- `chezmoi edit` decrypts the age file to a temp location, opens `$EDITOR`, then re-encrypts on save
- `autoCommit` is on, so the re-encrypted file is committed to the chezmoi source directory automatically (but not pushed)
- The old `encrypted_private_config.age` no longer exists — if you see `~/.ssh/config` with full host entries after apply, you're on a stale chezmoi source
