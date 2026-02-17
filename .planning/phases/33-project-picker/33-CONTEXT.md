# Phase 33: Project Picker — Context

## Decisions

### 1. Invocation & Key Binding

- **Trigger:** Command alias `pp` only (no ZSH key binding)
- **Shell function:** Required for `cd` in current shell (mise tasks run in subshell)
- **Mise task:** Also register as mise task for documentation/discoverability
- **Display mode:** Inline fzf (takes over terminal like Ctrl+R)
- **Action keys (fzf --expect):**
  - `Enter` → cd to project
  - `Ctrl+E` → open in detected editor
  - `Ctrl+O` → cd + open editor
  - Keys shown in fzf header

### 2. Project Display & Sorting

- **Line format:** `Parent/name  branch*  ~/full/path  2h ago  [IJ]`
  - Parent/name: one parent dir + project name (e.g., `Code/my-app`)
  - Branch: current git branch with `*` suffix if dirty (uncommitted changes)
  - Path: full path from home
  - Time: relative last-modified (e.g., `2h ago`, `3d ago`)
  - Editor: icon/label showing detected editor (`[IJ]` or `[SL]`)
- **Sorting:** zoxide frecency primary, mtime fallback for projects not in zoxide db
- **Preview pane:** Recent git log (10-15 commits, `git log --oneline --graph`)
- **Colours:** Dracula palette (consistent with Phase 32 fzf theme)

### 3. Editor Integration

- **Detection logic:**
  - `.idea/` present → IntelliJ IDEA
  - `.sublime-project` present → Sublime Text
  - Both present → most recently modified marker wins
  - Neither present → fallback to Sublime Text
- **Launch commands:**
  - IntelliJ: `idea <path>` (JetBrains Toolbox CLI)
  - Sublime: `subl <path>`
- **Behaviour:**
  - `Ctrl+E` → open editor only (stay in current dir)
  - `Ctrl+O` → cd first (instant), then launch editor in background
  - All editor launches are async (backgrounded, no shell blocking)
- **Visual indicator:** Editor icon/label shown in project list line

### 4. Scanning Scope & Project Definition

- **Parent directories:** `~/Projects`, `~/git` (hardcoded defaults)
- **Scan depth:** Default 2 levels, configurable via `PP_DEPTH` env var
- **Project detection:**
  - Primary: directories containing `.git/`
  - Secondary: directories containing project markers without `.git/`:
    `package.json`, `go.mod`, `Cargo.toml`, `pom.xml`, `Makefile`,
    `build.gradle`, `pyproject.toml`
- **Exclusions:** Skip `node_modules`, `.cache`, `vendor`, `target`, `build`, `dist`, `__pycache__`
- **Caching:**
  - Session-persistent (cache lives until shell restart)
  - Manual refresh key inside picker (e.g., `Ctrl+R` to rescan)
  - Cache stored in memory (shell variable) or temp file

## Deferred Ideas

None raised during discussion.

## Constraints

- Shell startup must remain < 150ms (no eager scanning at shell init)
- Cache scan must not block shell startup — scan lazily on first `pp` invocation
- `cd` must happen in current shell (not subshell) — requires shell function
- Dirty indicator adds ~50ms per project for `git status` — consider parallel or async
