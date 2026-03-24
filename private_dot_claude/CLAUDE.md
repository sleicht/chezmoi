# General Instructions

When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.
Don't be overly eager to agree with me, but think about the suggestions I make and speak up if you have another idea (better or worse).

## Language and Style
- Always use UK English
- Always answer in English even if I ask in another language

## Commits and Branches
Format: `<jira-ticket>: <type>[scope]: <description>`
Branch: `feature/<jira-ticket>-...`

Rules:
- Imperative present tense ("add" not "added")
- No capitalised first letter, no trailing period
- Body: max 10 bullet points, focus on "why" not "what"
- Only create feature branches when asked, or when on main/master/release/develop

## Keep It Minimal
- No features, abstractions, or error handling beyond what was asked
- Don't touch adjacent code, comments, or formatting
- Match existing style; every changed line traces to the request
- Clean up only what YOUR changes made unused

## Tool Preferences
- Prefer `fd` over `find` for file discovery — use `/fd` skill for syntax reference