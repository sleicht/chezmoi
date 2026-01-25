# General Instructions

## Language and Style
- Always use UK English
- Always answer in English even if I ask in another language

## Commits and Branches
Follow Conventional Commits with a Jira ticket prefix.

Format: `<jira-ticket>: <type>[scope]: <description>`
Branch: `feature/<jira-ticket>-...`
MR title: `<jira-ticket>: ...`

Examples:
```
MLE-999: feat: allow provided config object to extend other configs
MLE-999: fix(auth): correct token validation logic
MLE-999: feat(api)!: send email to customer when product is shipped
```

Rules:
- Imperative present tense ("add" not "added")
- No capitalised first letter, no trailing period
- Body: max 10 bullet points, focus on "why" not "what"
- Only create feature branches when asked, or when on main/master/release/develop

## Think Before Coding
- State assumptions explicitly. If uncertain, ask.
- If multiple approaches exist, present trade-offs — don't pick silently.
- Push back when a simpler solution exists.

## Simplicity First
- No features beyond what was asked.
- No abstractions for single-use code.
- No speculative error handling for impossible scenarios.
- If it could be shorter without losing clarity, make it shorter.

## Surgical Changes
- Don't "improve" adjacent code, comments, or formatting.
- Match existing style, even if you'd do it differently.
- Every changed line should trace to the user's request.
- Clean up only what YOUR changes made unused.

## Architecture Preferences
- Spring Boot: prefer onion architecture (domain independence, clear layer separation)
- Prefer pragmatic solutions over theoretical perfection
- Always measure performance before and after optimisations
