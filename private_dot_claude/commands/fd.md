# fd — File Finder Reference

Use `fd` (not `find`) for file discovery. Faster, simpler syntax, respects `.gitignore` by default.

## Syntax

```
fd [OPTIONS] [pattern] [path...]
```

Pattern is a **regex** by default. Omit pattern to list all files.

## Pattern Modes

| Flag | Mode | Example |
|------|------|---------|
| *(default)* | Regex | `fd 'config.*\.ya?ml'` |
| `-g` | Glob | `fd -g '*.json'` |
| `-F` | Fixed string | `fd -F 'TODO(human)'` |

Case: smart-case by default. Force with `-s` (sensitive) or `-i` (insensitive).

## Filtering

| Flag | Filter | Example |
|------|--------|---------|
| `-e ext` | Extension | `fd -e ts -e tsx` |
| `-t type` | Type: `f`ile, `d`ir, `l`ink, `x`ecutable, `e`mpty, `s`ocket, `p`ipe | `fd -t d node_modules` |
| `-d depth` | Max depth | `fd -d 2 -t f` |
| `-S size` | Size (`+`/`-` with `k`,`m`,`g`) | `fd -S +1m -e log` |
| `--changed-within` | Modified after | `fd --changed-within 1d` |
| `--changed-before` | Modified before | `fd --changed-before '2024-01-01'` |
| `--owner user:group` | Ownership | `fd --owner root` |

## Visibility

| Flag | Effect |
|------|--------|
| `-H` | Include hidden files (dotfiles) |
| `-I` | Include gitignored files |
| `-u` | Hidden + ignored (`-HI`) |
| `-uu` | Hidden + ignored + no ignore files |

## Exclusion

```bash
fd -E '*.min.js' -E node_modules    # exclude by pattern
fd --ignore-file .fdignore           # custom ignore file
```

## Output

| Flag | Effect |
|------|--------|
| `-a` | Absolute paths |
| `-0` | Null-separated (for `xargs -0`) |
| `-l` | Long listing (ls -l style) |
| `--max-results N` | Stop after N results |
| `-1` | Stop after first result |
| `--format fmt` | Custom output format |
| `-c never` | No colour (for piping) |

## Execution

Per-result (`-x`) or batched (`-X`):

```bash
fd -e png -x convert {} {.}.webp     # convert each PNG to WebP
fd -e rs -X rustfmt                   # format all Rust files at once
```

### Placeholders

| Placeholder | Meaning | For `/path/to/file.tar.gz` |
|-------------|---------|----------------------------|
| `{}` | Full path | `/path/to/file.tar.gz` |
| `{/}` | Filename | `file.tar.gz` |
| `{//}` | Parent dir | `/path/to` |
| `{.}` | Path without ext | `/path/to/file.tar` |
| `{/.}` | Filename without ext | `file.tar` |

## Recipes

```bash
# Find all test files
fd -e test.ts -e spec.ts -e test.tsx -e spec.tsx

# Large files in repo
fd -t f -S +10m

# Recently modified configs
fd -g '*.conf' --changed-within 7d

# Delete all .DS_Store files
fd -H -g .DS_Store -x rm

# Find and open in editor
fd -e md | fzf | xargs $EDITOR

# Count files by extension
fd -t f -e js | wc -l

# Find executable scripts
fd -t x -e sh

# Symlinks only
fd -t l

# Empty directories (cleanup)
fd -t e -t d -x rmdir
```
