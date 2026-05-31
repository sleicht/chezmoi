# Pi Agent to `omp` migration

This repository now manages a parallel `omp` setup while the existing Pi Agent files remain in place. The goal is to validate `omp` model auth, MCP, and high-value guardrails before removing any Pi-specific assets.

## Managed files

| Chezmoi source                                         | Deployed path                                 | Purpose                                                                                                                    |
|--------------------------------------------------------|-----------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `.chezmoidata.yaml`                                    | `~/.Brewfile`                                 | Keeps `pi-coding-agent` installed for Pi during the parallel rollout.                                                      |
| `private_dot_config/mise/config.toml.tmpl`             | `~/.config/mise/config.toml`                  | Manages `bun = "latest"`, which the `omp` bootstrap uses.                                                                |
| `run_once_after_install-omp.sh.tmpl`                   | one-time chezmoi script                       | Installs the parallel `omp` CLI with mise-managed Bun when `omp` is not already on `PATH`.                                 |
| `private_dot_omp/agent/config.yml.tmpl`                | `~/.omp/agent/config.yml`                     | Core `omp` settings, machine-specific model roles, theme, and local extension paths.                                       |
| `private_dot_omp/agent/models.yml.tmpl`                | `~/.omp/agent/models.yml`                     | Client-machine LiteLLM/OpenAI-compatible model definitions without committed credentials.                                  |
| `private_dot_omp/agent/mcp.json`                       | `~/.omp/agent/mcp.json`                       | IntelliJ MCP server configuration.                                                                                         |
| `private_dot_omp/agent/themes/dracula.json`            | `~/.omp/agent/themes/dracula.json`            | Dracula theme copied from the Pi setup for parity.                                                                         |
| `private_dot_omp/agent/plugins/local-dotfiles-tools/*` | `~/.omp/agent/plugins/local-dotfiles-tools/*` | Local `omp` plugin content, starting with the Gradle task-runner guardrail hook.                                           |

## What changed

- Pi remains installed and configured under `private_dot_pi/*` and `private_dot_pi-lens/*`.
- `bun` is managed through `private_dot_config/mise/config.toml.tmpl` so the `omp` install script has a documented runtime without adding another Homebrew formula.
- `run_once_after_install-omp.sh.tmpl` is the explicit `omp` installer; the existing `pi-coding-agent` Brew formula is not assumed to provide `omp`.
- `omp` gets its own source-managed agent directory under `private_dot_omp/agent/`.
- Client machines use the LiteLLM model role mapping from the old Pi settings:
  - `default`: `litellm/gpt-5-5:low`
  - `smol`: `litellm/claude-haiku-4-5:low`
  - `slow`: `litellm/claude-opus-4-6:low`
  - `plan` / `task`: `litellm/claude-sonnet-4-6:low`
- Personal machines intentionally rely on `omp` built-in providers and local auth.
- The IntelliJ MCP server is carried forward at `http://127.0.0.1:64342/stream`.
- The Pi `mise-just-enforcer.ts` behavior is ported as an `omp` pre-tool hook in `private_dot_omp/agent/plugins/local-dotfiles-tools/hooks/mise-just-enforcer.ts`.

## Local auth setup

Do not commit generated credentials or API keys.

For client LiteLLM usage, provide credentials locally with one of these approaches:

```bash
export LITELLM_BASE_URL="https://litellm.example.com"
export LITELLM_API_KEY="..."
```

or authenticate through `omp` so secrets live in the local `~/.omp/agent/agent.db`.

`models.yml.tmpl` references `$LITELLM_BASE_URL` and `$LITELLM_API_KEY`; the values must be supplied outside this repository.

## Extension triage

| Pi item | Migration status |
|---|---|
| `pi-provider-litellm` | Replaced by `private_dot_omp/agent/models.yml.tmpl` unless native `omp` model config proves insufficient. |
| `pi-mcp-adapter` | Replaced by native `omp` MCP config in `private_dot_omp/agent/mcp.json`. |
| `mise-just-enforcer.ts` | Ported to `private_dot_omp/agent/plugins/local-dotfiles-tools/hooks/mise-just-enforcer.ts`. |
| `firecrawl-search.ts` | Deferred; first try `omp` built-in web/search providers. |
| `pi-ghostty-notifier` | Deferred; port only if terminal notifications remain useful. |
| `pi-subagents`, `pi-clarify`, `pi-caveman` | Deferred/replaced by `omp` built-in subagents, plan mode, skills, and commands where possible. |
| `pi-lens` | Still Pi-only for now; see `docs/pi-lens.md`. |

## Validation checklist

Run these manually after unlocking the Bitwarden vault where needed:

```bash
rbw unlock
mise run d
chezmoi apply
mise run v
```

If `chezmoi apply` reports that `bun` was not available during the first run, make sure `mise` has installed the `bun = "latest"` tool from `~/.config/mise/config.toml`, then re-run `chezmoi apply` so `run_once_after_install-omp.sh.tmpl` can install `omp`.

Then validate the `omp` runtime:

```bash
omp --version
omp config path
omp -p 'hello'
```

In an interactive `omp` session, confirm:

1. The selected model/provider matches the expected client or personal machine behavior.
2. IntelliJ MCP tools load from `~/.omp/agent/mcp.json`.
3. Direct `gradle` / `./gradlew` shell calls are blocked in projects with `mise` or `just` task runners.
4. `pi` still starts successfully as the fallback agent.

## Rollback

Rollback during the parallel phase is simple:

1. Stop using `omp`.
2. Continue using `pi` with the untouched `private_dot_pi/*` and `private_dot_pi-lens/*` files.
3. Leave `private_dot_omp/*` in place until the gap is understood, or remove it in a follow-up cleanup if `omp` is abandoned.

Do not remove Pi assets until `omp` has been the confirmed daily driver for a stable trial period.

## Deferred cleanup

Only after the trial period:

- remove or disable `pi-coding-agent` from `.chezmoidata.yaml` if the package no longer provides anything required;
- remove `run_once_after_install-pi-packages.sh.tmpl`;
- remove `private_dot_pi/agent/*` and `private_dot_pi-lens/*` once their replacements or deprecations are accepted;
- re-run `mise run d` and `mise run v` manually after cleanup.
