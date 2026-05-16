# aiup-pi

> Pi package for the **AI Unified Process** — spec-driven development for Kotlin Multiplatform (Ktor + Compose) projects.
> Adapted from the [AI Unified Process Marketplace](https://github.com/sleicht/ai-unified-marketplace/).

## What This Is

A collection of `pi` skills that guide you through the AIUP methodology — from vision document to tested KMP application — directly inside your `pi` coding sessions.

## Installation

### From local path (chezmoi-managed)

After `chezmoi apply`, install from the deployed path:

```bash
pi install ~/.pi/packages/aiup-pi
```

### From git (for sharing)

If you publish this to your own git repo:

```bash
pi install git:github.com/YOURNAME/aiup-pi
```

### Try without installing

```bash
pi -e ~/.pi/packages/aiup-pi
```

## Skills

### Stack-Agnostic (Methodology)

| Skill                   | Triggers                                             | Input                  | Output                       |
|-------------------------|------------------------------------------------------|------------------------|------------------------------|
| `aiup-requirements`     | "write requirements", "create a PRD", "user stories" | `docs/vision.md`       | `docs/requirements.md`       |
| `aiup-entity-model`     | "entity model", "ER diagram", "database schema"      | `docs/requirements.md` | `docs/entity_model.md`       |
| `aiup-use-case-diagram` | "use case diagram", ".puml", "actor diagram"         | `docs/requirements.md` | `docs/use_cases.puml`        |
| `aiup-use-case-spec`    | "use case spec", "acceptance criteria", "scenarios"  | Use case IDs           | `docs/use_cases/UC-XXX-*.md` |

### KMP Stack-Specific (Construction)

| Skill                    | Triggers                                             | Input                  | Output                                   |
|--------------------------|------------------------------------------------------|------------------------|------------------------------------------|
| `aiup-flyway-migration`  | "migration", "flyway", "create tables"               | `docs/entity_model.md` | `src/main/resources/db/migration/V*.sql` |
| `aiup-implement-backend` | "implement backend", "ktor routes", "data access"    | Use case spec          | Backend code (DTOs, Exposed, Ktor, Koin) |
| `aiup-implement-ui`      | "implement UI", "compose screen", "frontend"         | Use case spec          | Compose Multiplatform screens            |
| `aiup-ktor-test`         | "write API tests", "ktor endpoints", "backend tests" | Use case spec          | `testApplication` tests                  |
| `aiup-compose-test`      | "compose tests", "UI tests", "screen tests"          | Use case spec          | `runComposeUiTest` tests                 |

## Workflow

```
docs/vision.md
       ↓  aiup-requirements
docs/requirements.md
       ↓  aiup-entity-model
docs/entity_model.md
       ↓  aiup-use-case-diagram
docs/use_cases.puml
       ↓  aiup-use-case-spec UC-001
docs/use_cases/UC-001-*.md
       ↓  aiup-flyway-migration
src/main/resources/db/migration/V*.sql
       ↓  aiup-implement-backend
Backend code (commonMain, server)
       ↓  aiup-implement-ui
Compose Multiplatform UI
       ↓  aiup-ktor-test + aiup-compose-test
Test classes
```

## MCP Servers

Install the KotlinDocs MCP server for inline API reference during implementation and testing. Add to your project's `~/.pi/settings.json` or global settings:

```json
{
  "mcpServers": {
    "KotlinDocs": {
      "type": "http",
      "url": "https://www.javadocs.dev/mcp"
    }
  }
}
```

## Recommended Project CLAUDE.md / AGENTS.md

Add this to your project root so `pi` has context on the methodology:

```markdown
# Project Context

This project follows the AI Unified Process. Read `docs/vision.md`,
`docs/requirements.md`, and `docs/entity_model.md` for product context
before making decisions.

## AIUP Workflow

1. Invoke `aiup-requirements` → derives `docs/requirements.md` from `docs/vision.md`
2. Invoke `aiup-entity-model` → derives `docs/entity_model.md` from requirements
3. Invoke `aiup-use-case-diagram` → produces `docs/use_cases.puml`
4. Invoke `aiup-use-case-spec` (with UC-XXX) → produces `docs/use_cases/UC-XXX-*.md`
5. Invoke `aiup-flyway-migration` → produces `src/main/resources/db/migration/V*.sql`
6. Invoke `aiup-implement-backend` → implements backend (Ktor + Exposed + Koin)
7. Invoke `aiup-implement-ui` → implements Compose Multiplatform UI
8. Invoke `aiup-ktor-test` + `aiup-compose-test` → tests

Never skip the spec for a use case before implementing it.
Always read the entity model before writing data access code.
```

## Dependencies

Requires:
- `pi` CLI with skill support
- Kotlin Multiplatform project with Ktor, Exposed, Koin, Compose
- PostgreSQL as configured in migrations
- Optional MCP server: KotlinDocs (configured above)

## Differences from Claude Code Marketplace

| AIUP Claude Plugin            | aiup-pi (this package)                |
|-------------------------------|---------------------------------------|
| `/requirements` slash command | `aiup-requirements` pi skill          |
| MCP in `.mcp.json`            | `mcpServers` in `~/.pi/settings.json` |
| Vaadin/jOOQ stack             | ❌ Excluded — this is Ktor/KMP only    |
| Claude Code plugin install    | `pi install` from git or local path   |

## License

MIT — same as upstream [ai-unified-marketplace](https://github.com/sleicht/ai-unified-marketplace/).
