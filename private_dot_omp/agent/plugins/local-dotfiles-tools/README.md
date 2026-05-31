# local-dotfiles-tools

Local `omp` plugin content managed from this chezmoi repository.

## Hooks

- `hooks/mise-just-enforcer.ts` blocks direct `gradle` / `gradlew` shell commands when the current project has `mise` or `just` task-runner configuration.

## Deferred Pi extensions

The remaining Pi extensions are intentionally not ported in the first parallel rollout. Revisit Firecrawl search/scrape, Ghostty notifications, status widgets, and workflow polish after base `omp` model, MCP, and guardrail parity is validated.