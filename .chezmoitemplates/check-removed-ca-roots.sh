# shellcheck shell=bash
# Detect roots that were removed from ca-bundle.trust.crt in the DSC repo but
# are still present in a local bundle, so the caller can force a refresh.

# SHA-256 fingerprints of removed roots.
# Append the fingerprint (uppercase, colon-separated) whenever a root is removed.
REMOVED_ROOTS=(
  # VeriSign Class 3 Public Primary CA (G1, MD2/1024-bit), removed 2026-11-23
  "E7:68:56:34:EF:AC:F6:9A:CE:93:9A:6B:25:5B:7B:4F:AB:EF:42:93:5B:50:A2:65:AC:B5:CB:60:27:E4:4E:70"
)

# Succeeds if the bundle still contains any certificate listed in REMOVED_ROOTS.
bundle_has_removed_root() {
  local bundle="$1" work fp removed c found=1
  [[ -f "$bundle" ]] || return 1
  work=$(mktemp -d)
  awk -v dir="$work" '
    /^-----BEGIN (TRUSTED )?CERTIFICATE-----$/ { file = dir "/c" ++n ".pem" }
    file { print > file }
    /^-----END (TRUSTED )?CERTIFICATE-----$/ { close(file); file = "" }
  ' "$bundle"
  for c in "$work"/c*.pem; do
    [[ -e "$c" ]] || continue
    fp=$(openssl x509 -in "$c" -noout -fingerprint -sha256 2>/dev/null) || continue
    fp="${fp#*=}"
    for removed in "${REMOVED_ROOTS[@]}"; do
      if [[ "$fp" == "$removed" ]]; then found=0; break 2; fi
    done
  done
  rm -rf "$work"
  return "$found"
}
