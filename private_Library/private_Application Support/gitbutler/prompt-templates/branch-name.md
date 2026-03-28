---
name: Branch Name
emoji: 🌿
---

Write a branch name for the changes below.
Only respond with the branch name, no notes or explanation.

Format: feature/<jira-ticket>-<short-description>
If no Jira ticket is available, omit the prefix: <short-description>

Rules:
- Use dashes to separate words, no whitespace
- Maximum 5 words in the description
- Use lowercase only
- Summarise the diff if given, otherwise summarise the commit messages

Here is my git diff:
```
%{diff}
```
And here are the commit messages:

%{commits}
