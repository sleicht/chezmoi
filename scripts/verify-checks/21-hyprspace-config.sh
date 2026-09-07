# shellcheck shell=bash
# Validate the current starter bindings and monitor assignments without secrets.

source_root="$SCRIPT_DIR/.."
chezmoi --config /dev/null --config-format yaml --source "$source_root" \
  --override-data '{"machine_type":"personal"}' execute-template \
  --file "$source_root/private_dot_config/hyprspace/config.toml.tmpl" | python3 -c '
import sys, tomllib
config = tomllib.loads(sys.stdin.read())
bindings = config["mode"]["main"]["binding"]
assert config["config-version"] == 2
assert bindings["alt-h"] == "focus left"
assert bindings["alt-7"] == "workspace 7"
assert "7" in config["persistent-workspaces"]
assert "7" in config["workspace-to-monitor-force-assignment"]
'
