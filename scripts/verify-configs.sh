#!/usr/bin/env bash
# =============================================================================
# verify-configs.sh — Plugin-based configuration verification runner
# =============================================================================
# Executes check files from scripts/verify-checks/ to validate that migrated
# configs are correctly deployed, template-error-free, and application-parsable.
#
# Each phase (8-12) adds its own check file to verify-checks/ (e.g.,
# 08-basic-configs.sh, 09-terminals.sh). This runner discovers and executes
# them, providing a pass/fail summary.
#
# Usage:
#   ./scripts/verify-configs.sh              # Run all checks
#   ./scripts/verify-configs.sh --phase 08   # Run only Phase 08 checks
#   ./scripts/verify-configs.sh --verbose    # Detailed output
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="$SCRIPT_DIR/verify-checks"
LIB_DIR="$SCRIPT_DIR/verify-lib"

# Colours for output (disabled if not terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  BOLD=''
  NC=''
fi

# --- Parse arguments ---

PHASE_FILTER=""
VERBOSE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --phase)
      shift
      PHASE_FILTER="${1:-}"
      if [ -z "$PHASE_FILTER" ]; then
        echo -e "${RED}ERROR:${NC} --phase requires a phase number (e.g., --phase 08)" >&2
        exit 2
      fi
      ;;
    --verbose|-v)
      VERBOSE=true
      ;;
    --help|-h)
      echo "Usage: $0 [--phase NN] [--verbose]"
      echo ""
      echo "Options:"
      echo "  --phase NN   Run only checks for phase NN (e.g., 08, 09)"
      echo "  --verbose    Show detailed output for each check"
      echo "  --help       Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}ERROR:${NC} Unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

# --- Source helper libraries ---

for lib in "$LIB_DIR"/*.sh; do
  if [ -f "$lib" ]; then
    # shellcheck source=/dev/null
    source "$lib"
  fi
done

# --- Discover and run check files ---

TOTAL=0
PASSED=0
FAILED=0

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    CONFIGURATION VERIFICATION          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ -n "$PHASE_FILTER" ]; then
  echo -e "Phase filter: ${BOLD}$PHASE_FILTER${NC}"
  echo ""
fi

# Collect check files
shopt -s nullglob
check_files=("$CHECKS_DIR"/*.sh)
shopt -u nullglob

if [ ${#check_files[@]} -eq 0 ]; then
  echo -e "${YELLOW}No check files found in $CHECKS_DIR${NC}"
  echo "Phases 8-12 will add check files as configs are migrated."
  echo ""
  exit 0
fi

for check_file in "${check_files[@]}"; do
  filename="$(basename "$check_file")"

  # Extract phase number from filename prefix (e.g., "08" from "08-basic-configs.sh")
  file_phase="${filename%%-*}"

  # Apply phase filter
  if [ -n "$PHASE_FILTER" ] && [ "$file_phase" != "$PHASE_FILTER" ]; then
    if $VERBOSE; then
      echo -e "  ${YELLOW}SKIP${NC} $filename (phase $file_phase, filter: $PHASE_FILTER)"
    fi
    continue
  fi

  TOTAL=$((TOTAL + 1))

  # Run check file in a subshell to isolate variables
  if (source "$check_file") 2>/dev/null; then
    PASSED=$((PASSED + 1))
    echo -e "  ${GREEN}PASS${NC} $filename"
  else
    FAILED=$((FAILED + 1))
    echo -e "  ${RED}FAIL${NC} $filename"
  fi
done

# --- Summary ---

echo ""
echo -e "${BOLD}=== Verification Summary ===${NC}"
echo ""
echo "  Total checks: $TOTAL"
echo -e "  Passed:       ${GREEN}$PASSED${NC}"
echo -e "  Failed:       ${RED}$FAILED${NC}"
echo ""

if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}Verification FAILED — $FAILED check(s) did not pass.${NC}"
  exit 1
else
  echo -e "${GREEN}All checks passed.${NC}"
  exit 0
fi
