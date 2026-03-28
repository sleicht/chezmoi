---
name: Commit Message
emoji: 💬
---

Write a commit message for the diff below.
Only respond with the commit message, no notes or explanation.

Format: <jira-ticket>: <type>[optional scope]: <description>
If no Jira ticket is known, omit the prefix: <type>[optional scope]: <description>
Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
Breaking changes: add ! after type/scope

Rules:
- Imperative mood ("add" not "added")
- No capitalised first letter, no trailing period
- Title max 50 characters
- Hard wrap body at 72 characters
- Focus on WHY the change was made, not WHAT changed — the diff shows the what
- Body: max 10 bullet points, prefer 2-3 high-level points
- Do not start any lines with the hash symbol
%{brief_style}
%{emoji_style}

Branch name (may contain Jira ticket): %{branch_name}

```
%{diff}
```
