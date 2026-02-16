---
phase: 30-verification
plan: 01
subsystem: verification
tags: [runbook, verification, acceptance-testing, shell, git, tools, smoke-test]
dependencies:
  requires:
    - phase: 28
      plan: 01
      reason: "Migration must be complete before verification"
    - phase: 29
      plan: 01
      reason: "Reintegration must be complete before verification"
  provides:
    - "RUNBOOK-05-verification.md: Step-by-step verification procedures for client migration"
    - "4 verification procedures covering shell, git, tools, and smoke test"
  affects:
    - subsystem: documentation
      impact: "Adds acceptance test runbook for v3.0 client migration"
tech_stack:
  added: []
  patterns:
    - "Procedure-based verification (manual steps with expected outputs)"
    - "Aggregate verification command for single-pass health check"
    - "Troubleshooting sections with specific remediation steps"
key_files:
  created:
    - path: ".planning/phases/30-verification/RUNBOOK-05-verification.md"
      purpose: "Verification runbook with 4 procedures for confirming migration success"
  modified: []
decisions: []
metrics:
  duration_min: 4
  tasks_completed: 2
  files_created: 1
  completed_at: "2026-02-15"
---

# Phase 30 Plan 01: Verification Runbook Summary

**One-liner:** Comprehensive verification runbook with 4 procedures covering shell functionality, git workflows, tool availability, and automated smoke test for client migration acceptance testing.

## What Was Built

Created RUNBOOK-05-verification.md, a step-by-step verification guide for the user to execute on the client Mac after completing Phase 28 (migration) and Phase 29 (reintegration). This runbook serves as the acceptance test for the entire v3.0 client migration.

### Runbook Structure

**Header sections:**
- Purpose: Confirm Dotbot-to-chezmoi migration success through systematic verification
- Prerequisites: Phase 28/29 complete, `chezmoi diff` clean, 15-20 minutes time budget
- Output: Verification report or issue list

**Procedure 1: Verify Shell Functionality (VERIF-01)**
- Objective: Confirm ZSH starts correctly with all interactive features
- Coverage:
  - Clean shell startup with styled prompt rendering
  - Startup time budget check (target <300ms)
  - Alias loading verification
  - oh-my-posh prompt engine check
  - Deferred plugin loading (zsh-defer/Sheldon)
  - Completion system initialisation
  - Atuin history keybinding configuration
- Troubleshooting: Template rendering, plugin configuration, startup profiling

**Procedure 2: Verify Git Workflows (VERIF-02)**
- Objective: Confirm git operations, mise tasks, and hooks function
- Coverage:
  - Git identity configuration (work name/email)
  - SSH authentication to GitHub
  - Non-destructive commit test (create, commit, revert)
  - Pre-commit hooks active (gitleaks scan)
  - mise task runner functionality
  - SSH remote verification
- Troubleshooting: SSH key deployment, hook installation, mise task deployment

**Procedure 3: Verify Tool Availability (VERIF-03)**
- Objective: Confirm runtimes, packages, and encryption infrastructure
- Coverage:
  - mise runtime availability (node, python, go)
  - Critical Homebrew packages (15 tools: chezmoi, mise, oh-my-posh, sheldon, atuin, zoxide, fzf, bat, lsd, git, pre-commit, gitleaks, age, etc.)
  - age encryption key presence and permissions (600)
  - chezmoi decryption capability
  - SSH key functionality
  - Homebrew health check
- Troubleshooting: Runtime installation, Brewfile deployment, age key provisioning, decryption diagnostics

**Procedure 4: Run Smoke Test (VERIF-04)**
- Objective: Run automated 13-check smoke test and verify all pass
- Coverage: References existing `scripts/zsh-smoke-test` script
- Expected output documented: 13 named checks with [PASS] status
- Check mapping to subsystems for targeted troubleshooting
- Troubleshooting: Script deployment, interactive shell execution

**Supporting sections:**
- Summary: Confirms migration complete if all procedures pass
- Aggregate verification command: Single-pass health check script
- Next steps: Phase 31 for rollback documentation, archive migration-audit directory

### Design Decisions

**Procedure-based format:**
- Each procedure maps to exactly one VERIF requirement
- Structure: Objective → Context → Steps → Expected Output → Troubleshooting → Output
- Consistent with RUNBOOK-01 through RUNBOOK-04 format

**Command-first approach:**
- Every verification step includes executable bash commands
- Comments explain expected behaviour
- Visual checks clearly marked (e.g., syntax highlighting colour)

**Troubleshooting integration:**
- Each procedure has dedicated troubleshooting section
- Maps symptoms to causes with specific remediation steps
- References cross-procedure dependencies (e.g., Procedure 1 for shell issues)

**Aggregate verification command:**
- Provides single-pass check of all subsystems
- 7 checks: chezmoi sync, shell startup, git identity, SSH access, mise runtimes, age key, smoke test
- Uses [PASS]/[FAIL]/[WARN] markers for clarity
- Non-destructive and safe to run repeatedly

**Smoke test integration:**
- References existing script rather than recreating
- Documents full expected output (13 checks) for comparison
- Maps failed checks to procedures for debugging

## How It Works

### Verification Flow

1. **User runs Procedure 1:** Verifies shell starts cleanly and interactive features work
2. **User runs Procedure 2:** Confirms git workflows (commit/push/hooks) function
3. **User runs Procedure 3:** Checks all tools and infrastructure are available
4. **User runs Procedure 4:** Runs automated smoke test for final confirmation
5. **Optional:** User runs aggregate verification command for quick health check

Each procedure is independent but builds on the previous (e.g., Procedure 4 may catch issues missed in 1-3).

### Troubleshooting Strategy

- Symptoms mapped to specific subsystems
- Remediation steps reference deployment mechanisms (chezmoi, Homebrew, mise)
- Cross-references between procedures for shared dependencies
- Diagnostic commands provided for investigation

### Success Criteria

Migration verified complete when:
- All 4 procedures pass with expected outputs
- Smoke test shows 13/13 checks passed
- Aggregate verification command shows all [PASS]
- User has confidence in daily workflow functionality

## Deviations from Plan

None - plan executed exactly as written.

## Testing Results

**Verification performed:**
- ✅ Runbook file created at correct path
- ✅ Contains exactly 4 procedures (one per VERIF requirement)
- ✅ User reviewed and approved runbook for accuracy

**Manual review checklist (user-verified):**
- Shell verification is thorough and covers daily-use features
- Git commit test is safe (non-destructive create/revert)
- Tool checks are comprehensive
- Smoke test expected output is accurate
- Runbook provides confidence in migration success verification

## Impact Assessment

### What Changed

**Added:**
- Verification runbook documentation (512 lines)
- 4 procedures with executable verification steps
- Aggregate verification command for quick health checks
- Troubleshooting sections for all subsystems

**Modified:**
- Nothing

### Breaking Changes

None - this is documentation only.

### Migration Required

None - runbook is ready to use immediately.

## Files Changed

### Created

**`.planning/phases/30-verification/RUNBOOK-05-verification.md`**
- Purpose: Step-by-step verification procedures for client migration acceptance testing
- Size: 512 lines
- Sections: 4 procedures + header + summary + aggregate command + next steps
- Coverage: VERIF-01 (shell), VERIF-02 (git), VERIF-03 (tools), VERIF-04 (smoke test)

### Modified

None

## Next Steps

### Immediate Actions

1. **User executes verification runbook on client Mac:** Follow RUNBOOK-05-verification.md procedures after completing Phase 28 and Phase 29
2. **Document verification results:** Note any failures or warnings for debugging
3. **Plan Phase 31:** Create rollback documentation for safety net procedures

### Future Enhancements

- Consider automating aggregate verification command as a mise task
- Potentially add verification screenshots to runbook for visual reference
- May add timing expectations for each procedure (currently 15-20 min total)

## Lessons Learned

### What Went Well

- Procedure structure consistent with previous runbooks (easy for user to follow)
- Comprehensive troubleshooting sections reduce need for ad-hoc debugging
- Aggregate verification command provides quick health check option
- Smoke test integration leverages existing automation

### What Could Be Improved

- Could add verification video/screenshots for first-time users
- Might benefit from verification result template for documentation
- Could include rollback triggers (what failures require rollback vs debug)

### Recommendations

- Keep runbook updated as tools/configuration evolve
- Consider creating automated version of aggregate verification as mise task
- Document verification results in STATE.md or separate verification report

## Self-Check: PASSED

### Created Files

```bash
$ [ -f "/Users/stephanlv_fanaka/.local/share/chezmoi/.planning/phases/30-verification/RUNBOOK-05-verification.md" ] && echo "FOUND: RUNBOOK-05-verification.md" || echo "MISSING: RUNBOOK-05-verification.md"
FOUND: RUNBOOK-05-verification.md
```

### Commits

```bash
$ git log --oneline --all | grep -q "f3f452a" && echo "FOUND: f3f452a" || echo "MISSING: f3f452a"
FOUND: f3f452a
```

All claimed artifacts verified present.
