---
description: "Generates Conventional Commit messages from git diffs with Jira ticket prefix. Use when the user requests to commit changes, write commit messages, or review staged changes. Invoked for phrases like 'commit these changes', 'write a commit message', 'help me commit', 'commit this', 'prepare a commit', 'stage and commit', 'what should my commit message be', 'draft a commit', 'ready to commit'. Also triggers when the user says 'commit' in the context of finishing work on a feature or fix. This skill handles both staged changes (git diff --cached) and already-committed changes (git show), preferring staged changes as the primary use case."
model: sonnet
---

# Git Commit Message Skill

You help users craft commit messages following Conventional Commits with a Jira ticket prefix.

## Key Rules

1. **Format**: `<jira-ticket>: <type>[optional scope]: <description>`
2. **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
3. **Imperative mood** in description — "add" not "added", no capitalised first letter, no trailing period
4. **Focus on WHY, not WHAT** — the diff shows the what; the message explains business value and intent
5. **Body**: max 10 bullet points, prefer 2-3 high-level points
6. **Breaking changes**: indicate with `!` after type/scope OR `BREAKING CHANGE:` in footer

## Reference

For the complete Conventional Commits specification, see: `${CLAUDE_PLUGIN_ROOT}/docs/conventional-commits-spec.md`

## Workflow

### 1. Determine what to analyse

Check for staged changes first, then fall back to the most recent commit:

```bash
# Check if there are staged changes
git diff --cached --stat
```

- **If staged changes exist**: use `git diff --cached` to analyse them (primary use case)
- **If no staged changes**: use `git show HEAD` to analyse the most recent commit

### 2. Get context

```bash
# Recent commits for style consistency
git log --oneline -10

# Current branch name (often contains ticket number)
git branch --show-current
```

### 3. Analyse the diff

- Read the full diff (`git diff --cached` or `git show HEAD`)
- Identify the type of change (feat, fix, refactor, etc.)
- Determine the scope from affected files/modules
- Extract the Jira ticket from the branch name if available

### 4. Generate the commit message

Create a message that:
- Includes the Jira ticket prefix (extract from branch name or ask the user)
- Uses the appropriate type and optional scope
- Provides a concise imperative description
- Body explains WHY the change was made, not WHAT changed
- Avoids listing low-level code changes (e.g. "add method X", "update function Y")

### 5. Write to file

- First, read `.commit-message.txt` using the **Read tool** (satisfies Write tool prerequisite if file exists; ignore "file not found" errors)
- Then use the **Write tool** to save the commit message to `.commit-message.txt`
- Inform the user that the message has been saved

## Interpreting User Intent

| User says | Action |
|-----------|--------|
| "commit this" / "commit these changes" / "help me commit" | Analyse staged changes (`git diff --cached`), generate message |
| "write a commit message" / "prepare a commit" | Analyse staged changes, generate message |
| "improve this commit message" / "rewrite the last commit" | Analyse HEAD (`git show HEAD`), generate improved message |
| "commit this as a fix" / "commit as feat" | Analyse staged changes, use specified type |
| "what should my commit message be" | Analyse staged changes, present message for review |

## Example Output

**File: `.commit-message.txt`**
```
MLE-123: feat(auth): add JWT token validation

Enhance authentication security to prevent unauthorised access from
expired or tampered tokens.

- Validates token expiry and signature using RS256
- Returns structured error responses for invalid tokens
```
