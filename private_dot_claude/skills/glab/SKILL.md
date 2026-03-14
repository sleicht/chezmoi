---
description: "MUST use this skill whenever the user mentions GitLab merge requests, MRs, pipelines, CI/CD, or GitLab issues. This includes: listing or viewing MRs, creating merge requests, approving or merging MRs, checking pipeline status, viewing CI job logs, running or retrying pipelines, linting .gitlab-ci.yml, creating or managing GitLab issues, or any request involving the glab CLI. This skill contains essential glab command syntax and flags that are required for correct usage in Claude Code — do not attempt glab commands without consulting this skill first. Trigger for: 'merge request', 'MR', 'pipeline', 'CI/CD', 'CI logs', 'GitLab issue', 'glab', patterns like '!123' or '!456', pipeline URLs, phrases like 'my MRs', 'open merge requests', 'pipeline status', 'approve MR', 'merge this', 'CI failed', 'rerun pipeline', 'create MR', 'MR review', 'draft MR', 'squash merge', 'rebase MR', 'MR diff', 'lint CI config'. Also trigger when the user is in a GitLab-hosted repo and asks to 'create a PR' or 'push and create review' — these map to merge requests. ANY message containing an MR reference pattern (!followed by digits, e.g. !123, !42) MUST trigger this skill."
model: haiku
---

# GitLab CLI (glab) Management Skill

You help users manage GitLab merge requests, issues, and CI/CD pipelines using the `glab` CLI tool.

## Key Rules

1. **Always use non-interactive output** — use `--output json` where available, avoid TUI/live modes (e.g. never use `--live` on `glab ci status`)
2. **Always use `--yes` or `--no-editor`** on create/write commands to skip interactive prompts
3. **Confirm before write operations** — before creating, approving, merging, closing, commenting, or running pipelines, show the user what you plan to do and ask for confirmation
4. **Present results readably** — format command output into clean tables or summaries for the user
5. **Use the Bash tool** to execute all glab commands
6. **For MR creation, follow Conventional Commits** — title format: `<TICKET>: <type>[scope]: <description>`, target branch defaults to `develop` unless specified

## Reference

For full command syntax, flags, and options, see: `${CLAUDE_PLUGIN_ROOT}/docs/glab-reference.md`

## Common Patterns

### Merge Request Management

```bash
# List my open MRs
glab mr list --mine

# List MRs awaiting my review
glab mr list --reviewer=@me

# View MR details
glab mr view 123

# View MR diff
glab mr diff 123

# Create MR (with Conventional Commits title)
glab mr create \
  --title "<TICKET>: <type>: <description>" \
  --description "$(cat MERGE_REQUEST.md)" \
  --target-branch develop \
  --source-branch "$(git branch --show-current)" \
  --remove-source-branch \
  --yes

# Create draft MR
glab mr create --fill --draft --target-branch develop --yes

# Checkout MR locally
glab mr checkout 123

# Approve MR
glab mr approve 123

# Merge MR (squash)
glab mr merge 123 --squash --remove-source-branch --yes

# Merge when pipeline succeeds
glab mr merge 123 --when-pipeline-succeeds --squash --yes

# Add comment to MR
glab mr note 123 -m "LGTM, approved"

# Rebase MR
glab mr rebase 123

# Update MR (e.g. add labels, change title)
glab mr update 123 --title "new title" -l enhancement
```

### MR Creation Workflow (Conventional Commits)

When creating a merge request:

1. Analyse changes: `git log --oneline develop..HEAD` and `git diff develop..HEAD --stat`
2. Check for MR template: `.gitlab/merge_request_templates/Feature_to_Develop.md`
3. Generate title following Conventional Commits: `<TICKET>: <type>: <description>`
4. Write description to `MERGE_REQUEST.md` with Summary (WHY not WHAT), Test Plan, and Checklist
5. Push branch: `git push --set-upstream origin $(git branch --show-current)`
6. Create MR: `glab mr create --title "..." --description "$(cat MERGE_REQUEST.md)" --target-branch develop --yes`
7. Report MR URL to user

### Issues

```bash
# List my issues
glab issue list --mine

# List issues assigned to me
glab issue list --assignee=@me

# View issue
glab issue view 42

# Create issue
glab issue create --title "Bug: login fails" -l bug --yes --no-editor

# Close issue
glab issue close 42

# Add comment
glab issue note 42 -m "Fixed in !123"

# Update issue
glab issue update 42 --title "Updated title" -l critical
```

### CI/CD

```bash
# Pipeline status for current branch
glab ci status

# List recent pipelines
glab ci list

# View pipeline details
glab ci view

# View CI job logs
glab ci trace

# Trigger new pipeline
glab ci run -b main

# Retry failed pipeline
glab ci retry 12345

# Cancel running pipeline
glab ci cancel 12345

# Lint .gitlab-ci.yml
glab ci lint

# Get pipeline details
glab ci get 12345
```

## Interpreting User Intent

- "show me my MRs" / "my open merge requests" / "list my MRs" -> `glab mr list --mine`
- "MRs waiting for my review" / "what needs my review" -> `glab mr list --reviewer=@me`
- "show me !123" / "view MR !123" / "what's in !123" -> `glab mr view 123`
- "create a merge request" / "create a PR" / "push and create MR" -> MR creation workflow (analyse changes, generate description, push, create)
- "create a draft MR" / "WIP merge request" -> `glab mr create --fill --draft --target-branch develop --yes`
- "approve !123" / "approve the MR" -> `glab mr approve 123` (confirm first)
- "merge !123" / "merge it" / "squash and merge" -> `glab mr merge 123 --squash --yes` (confirm first)
- "merge when green" / "merge when pipeline passes" -> `glab mr merge 123 --when-pipeline-succeeds --squash --yes`
- "what's the pipeline status" / "is CI passing" / "how's the build" -> `glab ci status`
- "CI logs" / "show me the job output" / "why did CI fail" -> `glab ci trace`
- "rerun the pipeline" / "retry CI" -> `glab ci retry <pipeline-id>` (confirm first)
- "lint the CI config" / "validate gitlab-ci.yml" -> `glab ci lint`
- "list GitLab issues" / "my issues" -> `glab issue list --mine`
- "issues assigned to me" -> `glab issue list --assignee=@me`
- "diff for !123" / "show MR changes" -> `glab mr diff 123`
- "rebase !123" / "rebase the MR" -> `glab mr rebase 123`
- "comment on !123" / "add a note to the MR" -> `glab mr note 123 -m "..."` (confirm first)

