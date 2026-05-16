# pi-lens

> Real-time inline code feedback for `pi` (AI coding agent).
> Installed via chezmoi dotfiles — managed globally, useful across all local projects.

## What It Does

`pi-lens` hooks into every `read`/`write`/`edit` tool call during a `pi` session and runs a language-aware pipeline:

1. **Secrets scan** — blocking; aborts the write/edit if credentials are detected.
2. **Auto-format** — formats touched files via `ktlint` (Kotlin), `biome` (TS/JS), `ruff` (Python), etc.
3. **Auto-fix** — safe autofixes from linters (Biome, Ruff, ESLint, stylelint, sqlfluff, RuboCop).
4. **LSP file sync** — opens/updates files in active language servers for diagnostics.
5. **Dispatch lint** — parallel runners: LSP, tree-sitter rules, ast-grep, fact rules, similarity detection.
6. **Cascade diagnostics** — review-graph impact showing what other files were affected.

All of this happens inline and is actionable:
- **Blocking issues** — stop progress until fixed.
- **Warnings** — summarized inline; detail via `/lens-booboo`.
- **Health/telemetry** — via `/lens-health`.

## Chezmoi Integration

| Chezmoi source file                          | Deployed to              | Purpose                                                       |
|----------------------------------------------|--------------------------|---------------------------------------------------------------|
| `private_dot_pi-lens/config.json`            | `~/.pi-lens/config.json` | Global preferences (widget hidden, deferred formatting)       |
| `run_once_after_install-pi-packages.sh.tmpl` | run script               | One-time `pi install npm:pi-lens` bootstrap                   |
| `dot_profile.tmpl`                           | `~/.profile`             | Sets `PILENS_DATA_DIR` to keep per-project state out of repos |

The install script is **idempotent** — it only installs if `pi-lens` is not already present. Updates are handled via `pi update`, not chezmoi.

### Environment Variables

| Variable          | Set in             | Value                    | Purpose                                               |
|-------------------|--------------------|--------------------------|-------------------------------------------------------|
| `PILENS_DATA_DIR` | `dot_profile.tmpl` | `$XDG_DATA_HOME/pi-lens` | Redirects `.pi-lens/` per-project caches out of repos |

## Configuration

### Global (`~/.pi-lens/config.json`)

```json
{
  "widget": {
    "visible": false
  },
  "format": {
    "enabled": true,
    "mode": "deferred"
  }
}
```

- `widget.visible: false` — hides the inline diagnostics widget by default. Toggle per-session with `/lens-widget-toggle`.
- `format.mode: deferred` — queues formatting until `agent_end` (after all tool calls). Use `"immediate"` for per-edit formatting.

### Per-Project: LSP Warm Files

For language servers that build indices lazily (e.g. Kotlin, Java), create `.pi-lens/lsp.json` in the project root:

```json
{
  "warmFiles": [
    "src/main/kotlin/Application.kt"
  ]
}
```

This seeds the server so the first symbol query isn't cold.

## Kotlin / Ktor Support

### What Works

| Capability                 | Kotlin/Ktor                                        |
|----------------------------|----------------------------------------------------|
| **LSP**                    | ✓ `kotlin-language-server` auto-detected/installed |
| **Linting**                | `ktlint` (auto-installed from GitHub releases)     |
| **Formatting**             | `ktlint`                                           |
| **Secrets guard**          | ✓ (language-agnostic)                              |
| **Read-before-edit guard** | ✓ (file-level & line-range tracking)               |

### Limitations

- **No tree-sitter rules** for Kotlin. TypeScript/Python/Go have blocking structural rules (e.g. SQL injection guards); Kotlin does not.
- **No symbol expansion** on read. For Kotlin, line-range tracking is literal; you must have read the target lines.
- **Nothing Ktor-specific** — `ktlint` + Kotlin LSP are general-purpose; Ktor `Routing`, `Application`, or server config get no special treatment.
- **Read-guard on Ktor routing** — when you edit a `Routing` block in a large file, pi-lens checks you've read those lines. Use `/lens-allow-edit <path>` for a one-off override if needed.

### Ktor Project Setup Checklist

1. Add to `.gitignore`:
   ```gitignore
   .pi-lens/
   ```
2. Add `.pi-lens/lsp.json` with `warmFiles` pointing to your entry class.
3. (Optional) Add `.semgrep.yml` and run `/lens-semgrep init` for security scanning beyond secrets detection.

## Java / Spring Boot Support

### What Works

| Capability                 | Java / Spring Boot                             |
|----------------------------|------------------------------------------------|
| **LSP**                    | ✓ Java language server auto-detected/installed |
| **Compilation checks**     | `javac` dispatch runner                        |
| **Formatting**             | ✗ *None built-in* (see below)                  |
| **Secrets guard**          | ✓ (language-agnostic)                          |
| **Read-before-edit guard** | ✓ (file-level & line-range tracking)           |

### Limitations

- **No built-in formatter** — pi-lens does not ship with a Java formatter (unlike Kotlin which has `ktlint`). Spring Boot projects typically rely on IDE formatting, Spotless, or Google Java Format configured in Maven/Gradle.
- **No tree-sitter rules** for Java. There are no blocking structural rules for Java (e.g. no injection guards, no null-safety checks).
- **No Spring Boot-specific rules** — `Application`, `@RestController`, `@Entity`, or Spring Security annotations get no special treatment.
- **No symbol expansion** on read. Java is not in the read-expansion supported list (TypeScript, Python, Go, Rust, Ruby). You must read the literal line ranges you intend to edit.
- **LSP startup cost** — Java language servers (e.g. Eclipse JDT) are heavy. Use `warmFiles` aggressively to avoid cold-start latency when `pi` opens the project.

### Spring Boot Project Setup Checklist

1. Add to `.gitignore`:
   ```gitignore
   .pi-lens/
   ```
2. Add `.pi-lens/lsp.json` with `warmFiles` pointing to your Spring Boot main class and key config:
   ```json
   {
     "warmFiles": [
       "src/main/java/com/example/Application.java",
       "src/main/java/com/example/config/SecurityConfig.java"
     ]
   }
   ```
3. Ensure a Java LSP is available on PATH or allow pi-lens to install/manager it. If using VS Code's JDT server (`jdtls`), make sure it's on PATH.
4. Consider adding a project-level formatter (Spotless, palantir-java-format) since pi-lens won't format Java files itself.

## Key Commands

| Command                                    | Action                                               |
|--------------------------------------------|------------------------------------------------------|
| `/lens-toggle`                             | Enable/disable pi-lens for the session               |
| `/lens-widget-toggle`                      | Show/hide the inline diagnostics widget              |
| `/lens-booboo`                             | Full quality/security report for the project         |
| `/lens-health`                             | Runtime health, latency, diagnostic telemetry        |
| `/lens-tools`                              | Tool installation status (global/auto-installed/npx) |
| `/lens-tdi`                                | Technical Debt Index and health trend                |
| `/lens-allow-edit <path>`                  | Override read guard for a single file                |
| `/lens-semgrep status/init/enable/disable` | Manage experimental Semgrep dispatch                 |

## CLI Flags (use when starting `pi`)

```bash
pi --no-lens             # Start with pi-lens disabled
pi --no-lsp              # Disable unified LSP diagnostics
pi --immediate-format      # Format after each edit (not deferred)
pi --no-autoformat         # Skip formatting entirely
pi --no-autofix            # Skip auto-fix
pi --no-read-guard         # Disable read-before-edit (not recommended)
pi --lens-guard            # Block git commit/push on unresolved blockers
```

## Suppressing Findings

For inline suppression on a flagged line or the line above:

**TypeScript / JavaScript:**
```typescript
// pi-lens-ignore: rule-id
const result = eval(userInput);
```

**Kotlin / Java:**

Neither language has tree-sitter rules yet. For Semgrep or LSP diagnostics, suppression is tool-specific. For Semgrep, use inline comments matching the rule's pattern.

## Dependencies & Auto-Install

`pi-lens` auto-installs many tools via npm or GitHub releases. Relevant to JVM-language workflows:

| Tool     | Purpose            | Auto-installed | Install gate   |
|----------|--------------------|----------------|----------------|
| `ktlint` | Kotlin lint/format | Yes            | GitHub release |

Other tools (Biome, Ruff, ESLint, etc.) install on-demand based on project config. Java language servers are auto-detected from PATH or project tooling — pi-lens does not auto-install a Java LSP from GitHub releases as of the current version.

## Update Path

- `pi update` — updates `pi` and all non-pinned packages including `pi-lens`.
- `pi update npm:pi-lens` — update this package only.
- Chezmoi **does not** manage `pi-lens` versions — it only bootstraps the initial install.

## See Also

- [pi-lens on npm](https://www.npmjs.com/package/pi-lens)
- [pi-lens repo](https://github.com/apmantza/pi-lens)
- [Pi packages documentation](/opt/homebrew/Cellar/pi-coding-agent/0.74.0/libexec/lib/node_modules/@earendil-works/pi-coding-agent/docs/packages.md)
- `pi-lens --help` — runtime help inside a `pi` session
