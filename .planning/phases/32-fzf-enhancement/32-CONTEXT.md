# Phase 32: fzf Enhancement - Context

**Gathered:** 2026-02-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Configure fzf-tab with rich, context-aware completion previews and enhance fzf widget previews (Ctrl+T, Alt+C). All tools (fzf, fzf-tab, bat, eza, carapace) are already installed — this phase wires them together. No new tool installation. Shell startup must stay under 150ms.

</domain>

<decisions>
## Implementation Decisions

### Preview styling
- bat theme: Dracula — consistent with fzf colour scheme
- Line numbers: always shown in file previews
- eza tree depth: 2 levels for directory previews
- eza icons: enabled (nerd font icons for file types)

### fzf layout & colours
- Preview window position: bottom
- Preview window size: 40% of fzf window
- Colour scheme: Dracula — matching bat theme for visual consistency
- Border style: rounded corners

### Context-specific preview content
- **Files:** bat with Dracula theme, line numbers, syntax highlighting
- **Directories:** eza tree, 2 levels deep, with icons
- **Processes (kill):** Claude's discretion on detail level
- **Environment variables:** show current value, truncate after ~200 chars for long values
- **Git log (checkout/branch):** oneline format with graph (compact branch visualisation)
- **Git diff (add/stage):** Claude's discretion on full diff vs stat+diff

### Claude's Discretion
- Process preview detail level (full ps output vs minimal)
- Git diff preview format (full diff vs stat+diff — pick what fits 40% bottom pane best)
- Any additional completion contexts beyond those listed in requirements
- Exact Dracula colour values for fzf `--color` flag

</decisions>

<specifics>
## Specific Ideas

- Dracula theme throughout — bat, fzf chrome, and borders should feel like one unified tool
- Preview pane at bottom with rounded border gives a modern, contained feel
- Git log graph format keeps branch topology visible in a compact space

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 32-fzf-enhancement*
*Context gathered: 2026-02-16*
