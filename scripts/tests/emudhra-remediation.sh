#!/bin/bash
# Uses public advisory certificates; requires httpie, jq, OpenSSL, chezmoi and a JDK.
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# shellcheck source=.chezmoitemplates/filter-emudhra.sh
source "$repo_dir/.chezmoitemplates/filter-emudhra.sh"

https --ignore-stdin --check-status --timeout=30 --body GET \
  https://emudhra.we-have-a-problem.com/roots.json |
  jq -er '.[] | select(.name != "emSign Root CS CA - G3") | .pem' > "$test_dir/affected.pem"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj '/CN=Retained Test Root' \
  -keyout "$test_dir/key.pem" -out "$test_dir/retained.pem" 2>/dev/null
cat "$test_dir/affected.pem" "$test_dir/retained.pem" > "$test_dir/bundle.pem"
chmod 640 "$test_dir/bundle.pem"
cp -p "$test_dir/bundle.pem" "$test_dir/original.pem"

filter_emudhra_roots "$test_dir/bundle.pem"
cmp "$test_dir/retained.pem" "$test_dir/bundle.pem"
cmp "$test_dir/original.pem" "$test_dir/bundle.pem.bak"
[[ $(stat -f '%Lp' "$test_dir/bundle.pem") == 640 ]]
filter_emudhra_roots "$test_dir/bundle.pem"
cmp "$test_dir/retained.pem" "$test_dir/bundle.pem"
cmp "$test_dir/original.pem" "$test_dir/bundle.pem.bak"

# Invalid PEM and an all-affected bundle must fail without changing the input.
for invalid in malformed invalid_body empty_result; do
  if [[ "$invalid" == malformed ]]; then
    printf '%s\n' '-----BEGIN CERTIFICATE-----' 'invalid' > "$test_dir/invalid.pem"
  elif [[ "$invalid" == invalid_body ]]; then
    printf '%s\n' '-----BEGIN CERTIFICATE-----' 'invalid' '-----END CERTIFICATE-----' \
      > "$test_dir/invalid.pem"
  else
    cp "$test_dir/affected.pem" "$test_dir/invalid.pem"
  fi
  cp "$test_dir/invalid.pem" "$test_dir/before.pem"
  set +e
  # The redirection exposes EXIT-trap scope bugs that leak the work directory.
  ( set -e; filter_emudhra_roots "$test_dir/invalid.pem" > /dev/null )
  status=$?
  set -e
  [[ "$status" -ne 0 ]]
  cmp "$test_dir/before.pem" "$test_dir/invalid.pem"
  [[ ! -e "$test_dir/invalid.pem.bak" ]]
  [[ -z "$(compgen -G "$test_dir/.emudhra.*")" ]]
done

https --ignore-stdin --check-status --timeout=30 --download \
  --output "$test_dir/chains.zip" GET https://emudhra.we-have-a-problem.com/chains.zip
unzip -q "$test_dir/chains.zip" -d "$test_dir"
for chain in "$test_dir"/chains/*.pem; do
  openssl verify -no-CApath -no-CAstore -CAfile "$test_dir/original.pem" \
    -untrusted "$chain" "$chain" > /dev/null
  set +e
  openssl verify -no-CApath -no-CAstore -CAfile "$test_dir/bundle.pem" \
    -untrusted "$chain" "$chain" > "$test_dir/verification.log" 2>&1
  status=$?
  set -e
  [[ "$status" -ne 0 ]]
  rg -q 'unable to get local issuer certificate' "$test_dir/verification.log"
done

# Java keystores: dry runs change nothing; real runs remove only affected aliases.
java_home=$(java -XshowSettings:properties -version 2>&1 |
  awk '$1 == "java.home" { sub(/^[^=]*= /, ""); print }')
jdk="$test_dir/jdks/test-jdk"
keytool="$jdk/bin/keytool"
mkdir -p "$jdk/bin" "$jdk/lib/security"
ln -s "$java_home/bin/keytool" "$keytool"
awk -v directory="$test_dir" '/^-----BEGIN/ { file = directory "/affected-" ++count ".pem" } { print > file }' \
  "$test_dir/affected.pem"
for pem in "$test_dir"/affected-*.pem "$test_dir/retained.pem"; do
  "$keytool" -importcert -noprompt -alias "$(basename "$pem" .pem)" -file "$pem" \
    -keystore "$jdk/lib/security/cacerts" -storepass changeit > /dev/null 2>&1
done
cp "$jdk/lib/security/cacerts" "$test_dir/cacerts.before"
chezmoi --source "$repo_dir" execute-template \
  < "$repo_dir/dot_local/bin/executable_remove-emudhra-certs.tmpl" > "$test_dir/remove-emudhra-certs"
bash "$test_dir/remove-emudhra-certs" --dry-run "$test_dir/jdks" > "$test_dir/java.log" 2>&1
cmp "$test_dir/cacerts.before" "$jdk/lib/security/cacerts"
rg -q '^==> 3 affected certificate\(s\) in 1 of 1 keystore\(s\)$' "$test_dir/java.log"
bash "$test_dir/remove-emudhra-certs" "$test_dir/jdks" > "$test_dir/java.log" 2>&1
[[ $("$keytool" -list -keystore "$jdk/lib/security/cacerts" -storepass changeit 2>/dev/null |
  rg -c 'trustedCertEntry') == 1 ]]
"$keytool" -list -alias retained -keystore "$jdk/lib/security/cacerts" -storepass changeit > /dev/null 2>&1

echo 'PASS: affected roots removed; unrelated certificate and permissions retained; reruns preserve backup; invalid inputs unchanged'
echo 'PASS: all 12 advisory chains trusted before filtering and rejected afterwards'
echo 'PASS: Java dry run unchanged; real run removed only affected aliases'
