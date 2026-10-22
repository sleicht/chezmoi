# shellcheck shell=bash
# Distrust affected roots by public key, including cross-signed copies.
# https://emudhra.we-have-a-problem.com/#macos-curl

# Prints "affected" or "retained"; fails on unreadable certificates.
emudhra_root_status() {
  local spki_hash
  spki_hash=$(openssl x509 -in "$1" -pubkey -noout |
    openssl pkey -pubin -outform DER |
    openssl dgst -sha256 -r) || return
  case "${spki_hash%% *}" in
    bd153ed7b0434f6886b17bce8bbe84ed340c7132d702a8f4fa318f756ecbd6f3|\
    c619e4780ed8e0abeda24ad732567de4383a7ea941338f6d1a7d1b49ac792fe9|\
    8d417db2dd8bf5e3084d1e3f196d583849d81bdd4c00c70b9d39369e96b8c782)
      echo affected ;;
    *)
      echo retained ;;
  esac
}

filter_emudhra_roots() (
  set -euo pipefail
  bundle="$1"
  work_dir=$(mktemp -d "${bundle%/*}/.emudhra.XXXXXX")
  trap 'rm -rf "$work_dir"' EXIT

  # Retain permissions and ownership for the replacement.
  cp -p "$bundle" "$work_dir/filtered.pem"
  : > "$work_dir/filtered.pem"
  awk -v directory="$work_dir" '
    /^-----BEGIN (TRUSTED )?CERTIFICATE-----$/ {
      if (writing) exit 1
      writing = 1
      file = directory "/cert-" ++count ".pem"
    }
    writing { print > file }
    /^-----END (TRUSTED )?CERTIFICATE-----$/ {
      if (!writing) exit 1
      close(file)
      writing = 0
    }
    END { if (writing || !count) exit 1 }
  ' "$bundle"

  removed=0
  retained=0
  for certificate in "$work_dir"/cert-*.pem; do
    status=$(emudhra_root_status "$certificate")
    if [[ "$status" == affected ]]; then
      removed=$((removed + 1))
    else
      cat "$certificate" >> "$work_dir/filtered.pem"
      retained=$((retained + 1))
    fi
  done

  if [[ "$retained" -eq 0 ]]; then
    echo "Refusing to empty CA bundle: $bundle" >&2
    exit 1
  fi
  if [[ "$removed" -eq 0 ]]; then
    return 0
  fi

  # Never replace the first backup on subsequent runs.
  if [[ ! -e "$bundle.bak" ]]; then
    cp -p "$bundle" "$bundle.bak"
  fi
  mv -f "$work_dir/filtered.pem" "$bundle"
  echo "==> Removed $removed affected root certificate(s) from $bundle"
)
