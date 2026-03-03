# Code Review

Review the current changeset for correctness, security, performance, and maintainability. Produce structured, actionable feedback grouped by severity.

## Process

### 1. Identify Changes

```bash
git diff HEAD
```

If the diff is empty, fall back to `git diff main...HEAD` to capture the full branch delta.

### 2. Categorise Files

Group changed files by type and risk:
- **High risk**: security-sensitive code, configuration, infrastructure, auth, data access
- **Medium risk**: business logic, API contracts, shared utilities
- **Low risk**: tests, documentation, comments, formatting

Allocate review depth proportionally — spend the most time on high-risk files.

### 3. Review Checklist

**Correctness**
- Logic errors, off-by-ones, edge cases
- Null/undefined handling and missing error paths
- Incorrect assumptions about data shape or state
- Race conditions or ordering issues

**Security**
- Injection vectors (SQL, command, template, XSS)
- Auth/authz bypass or privilege escalation
- Secret exposure (keys, tokens, credentials in code or config)
- OWASP top 10 where applicable

**Performance**
- N+1 queries, unbounded loops, missing pagination
- Unnecessary allocations or copies in hot paths
- Missing indexes for new query patterns
- Blocking calls in async contexts

**Maintainability**
- Unclear naming, excessive complexity, tight coupling
- Missing or premature abstractions
- Code that will confuse the next reader
- Breaking changes to public interfaces without migration path

**Test coverage**
- New behaviour without corresponding tests
- Tests that don't assert meaningful outcomes
- Flaky patterns (timing, ordering, shared state)

## Output Format

Group findings by severity, not by file. Include file path and line reference for each finding.

### CRITICAL (must fix before merge)
- Security vulnerabilities
- Data loss or corruption risks
- Breaking changes without migration
- Correctness bugs in core logic

### HIGH (should fix)
- Performance degradation risks
- Missing error handling for likely failure modes
- Gaps in test coverage for new behaviour

### SUGGESTIONS (consider improving)
- Readability and naming improvements
- Optimisation opportunities
- Additional edge-case coverage

For each finding: state the problem, explain why it matters, and suggest a fix.

## What NOT to Flag

- Comment-only or whitespace changes
- Style preferences already enforced by linters or formatters
- Nitpicks on code the changeset did not touch
- Hypothetical issues with no plausible trigger
