## Version control

- Use GitButler (`but`) for version-control write operations, including branching, committing, pushing, and history edits.
- Assume multiple agents may be working in this repository. Do not move, amend, squash, discard, commit, push, or otherwise modify another agent's work unless the user asks.
- Use a dedicated GitButler branch for each agent session, unless the user asks for a different branch structure. Commit only changes that belong to that session.
- Do not push or open merge requests unless the user asks.
- Keep commit messages and merge request descriptions succinct: explain what changed, why it changed, and any important decision.
- For small cleanup or follow-up fixes, amend an unpublished local commit when the change clearly belongs with that commit's intent.
- Do not create tiny fixup commits unless I ask.
- Use GitButler to move the relevant changes into the commit where they belong.
- Ask before rewriting pushed, reviewed, shared, or ambiguous history.
- Commit after a working checkpoint, when the requested change is complete and  relevant checks have passed or been reported.
- Treat checkpoint commits as local savepoints, not final review history.
- When I ask you to tidy the history, use GitButler to squash commits, reword commits, and move changes between commits where appropriate.
- Only tidy unpublished local history unless I explicitly authorize changing pushed or shared history.
- If this session depends on another in-flight branch, stack its branch on top of that dependency instead of mixing the changes.
- If this session is working in a stack, put commits on the branch where they belong.
- Ask before moving commits onto lower, pushed, reviewed, or shared branches.
- Use `but move` for branch stacking and restacking. Do not recreate branches to simulate stacking.
- For stacked branches, create merge requests with `but pr`, not `gh`, so GitButler keeps the right PR base branches and stack metadata.
- When I say "ship it", commit this session's changes on its dedicated GitButler branch, creating one if needed.
- Push the branch and open or update its merge request with GitButler.
- Reuse the existing branch or merge request for this session when one already exists.
- When GitButler status shows new changes on the target branch, run
  `but pull --check`.
- If the check is clean and the update affects only this session's branches, update the workspace with `but pull`.
- If the check reports conflicts or the update would affect another agent's branch, ask before updating.
- If I ask you to handle update conflicts, use GitButler's conflict tools. Ask before resolving semantic conflicts, dependency updates, generated files, or conflicts involving another person's work.

## Commits and Branches
Format: `<jira-ticket>: <type>(scope): <description>`
Branch: `feature/<jira-ticket>-...`

Rules:
- Imperative present tense ("add" not "added")
- No capitalised first letter, no trailing period
- Body: max 10 bullet points, focus on "why" not "what"
- Only create feature branches when asked, or when on main/master/release/develop
- When on `gitbutler/workspace` branch, use the `GitButler` skill/cli for all git operations (commit, branch, push) — never use raw git checkout/branch commands
