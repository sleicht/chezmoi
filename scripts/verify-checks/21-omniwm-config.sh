# shellcheck shell=bash
# Check the trial against the retained Aerospace source without opening the vault.
python3 - "$SCRIPT_DIR/.." <<'PY'
import re
import sys
import tomllib
import uuid
from pathlib import Path

root = Path(sys.argv[1])
config = tomllib.loads((root / "private_dot_config/omniwm/settings.toml").read_text())
aerospace = (root / "private_dot_config/aerospace/aerospace.toml.tmpl").read_text()
assert config["schemaVersion"] == 3
assert config["general"]["defaultLayoutType"] == "dwindle"
assert config["appearance"]["mode"] in {"automatic", "light", "dark"}
assert config["workspaceBar"]["position"] in {"overlappingMenuBar", "belowMenuBar"}
assert config["gaps"]["size"] == 3
assert set(config["gaps"]["outer"].values()) == {5}
assert not config["borders"]["enabled"]
assert not config["clipboard"]["historyEnabled"]
assert not config["quakeTerminal"]["enabled"]

hotkeys = config["hotkeys"]
bindings = {row["id"]: row["binding"] for row in hotkeys}
assert len(bindings) == len(hotkeys) == 188
assigned = [value for value in bindings.values() if value != "Unassigned"]
assert len(assigned) == len(set(assigned)), "Conflicting shortcuts"
assert bindings["closeFocusedWindow"] == "Control+Q"
assert bindings["toggleFullscreen"] == "Control+F"
assert bindings["move.down"] == "Control+Option+Right Arrow"
assert bindings["move.right"] == "Control+Option+Down Arrow"
for i in range(8):
    assert bindings[f"switchWorkspaceSlot.{i + 1}"] == f"Control+{i}"
    assert bindings[f"moveToWorkspaceSlot.{i + 1}"] == f"Control+Shift+{i}"

workspaces = config["workspaces"]
assert [row["name"] for row in workspaces] == list("01234567")
for row in workspaces:
    uuid.UUID(row["id"])
    assert row["monitorAssignment"]["type"] == ("secondary" if row["name"] == "7" else "main")

rules = config["appRules"]
assert len({row["id"] for row in rules}) == len(rules)
actual = {row["bundleId"]: row for row in rules if row["bundleId"]}
expected = {}
for app, commands in re.findall(r"if.app-id = '([^']+)'\n(?:[^\n]*\n)*?run = \[([^\n]+)\]", aerospace):
    expected[app] = (re.search(r"move-node-to-workspace (\d)", commands)[1],
                     "float" if "layout floating" in commands else "tile")
assert len(expected) == 22
assert actual.keys() == expected.keys(), "App assignment lost or added"
for app, (workspace, layout) in expected.items():
    assert actual[app]["assignToWorkspace"] == workspace
    assert actual[app]["layout"] == layout
fallback, = [row for row in rules if not row["bundleId"]]
assert fallback["layout"] == "float" and fallback["titleRegex"] == ".*"
print("OmniWM: 188 actions, 8 workspaces, 22 Aerospace app assignments verified")
PY
