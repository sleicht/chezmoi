import shutil
from fixtures import Fixture, ROOT


class IntegrationTests(Fixture):
    def test_provider_source_and_tsconfig_changes_trigger_rebuild(self):
        source = self.home / "source"
        base = "private_dot_pi/agent/extensions/"
        script = base + "run_onchange_after_02-build-litellm-provider.sh.tmpl"
        self.write(source / script, (ROOT / script).read_text())
        provider = source / base / "pi-provider-litellm"
        self.write(provider / "package.json", "{}")
        ts = self.write(provider / "src/index.ts", "export {}")
        config = self.write(provider / "tsconfig.json", "{}")
        before = self.render(script, source=source)
        ts.write_text("export const changed = true")
        after = self.render(script, source=source)
        self.assertNotEqual(before, after)
        config.write_text('{"compilerOptions":{}}')
        self.assertNotEqual(after, self.render(script, source=source))

    def test_budget_rebuild_tracks_rendered_values(self):
        script = "run_onchange_after_07-budget-overlay.sh.tmpl"
        self.synthetic_vault()
        self.stub("chezmoi", 'printf "%s" "${FIXTURE_KEY:-fixture-one}"')
        before = self.render(script, machine="client")
        self.env["FIXTURE_URL"] = "https://changed.invalid"
        after = self.render(script, machine="client")
        self.assertNotEqual(before, after)
        self.env["FIXTURE_KEY"] = "fixture-two"
        rotated = self.render(script, machine="client")
        self.assertNotEqual(after, rotated)
        self.assertNotIn("fixture-two", rotated)

    def test_service_check_distinguishes_missing_compose_from_daemon_errors(self):
        content = (ROOT / "scripts/verify-checks/20-omp-servers.sh").read_text()
        path = self.write(self.home / "service-check.sh", self.shell_home(content))
        self.write(self.home / ".config/omp-servers/docker-compose.yml", "services: {}")
        self.stub("docker", 'exit 1')
        self.assertEqual(self.script(f'source "{path}"', check=False).returncode, 77)
        self.stub("docker", '[ "$2" = version ] && exit 0; exit 1')
        self.assertEqual(self.script(f'source "{path}"', check=False).returncode, 1)
        self.stub("docker", 'exit 0')
        self.assertEqual(self.script(f'source "{path}"', check=False).returncode, 77)

    def test_verifier_distinguishes_skip_failure_and_no_matching_checks(self):
        runner = self.write(self.home / "scripts/verify-configs.sh", (ROOT / "scripts/verify-configs.sh").read_text())
        checks = runner.parent / "verify-checks"
        self.write(checks / "01-skip.sh", "return 77\n")
        failed = self.write(checks / "02-failure.sh", "echo fixture-error >&2\nfalse\necho must-not-run\n")
        result = self.run_cmd(["bash", str(runner)], check=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("SKIP 01-skip.sh", result.stdout)
        self.assertIn("FAIL 02-failure.sh", result.stdout)
        self.assertNotIn("must-not-run", result.stdout)
        self.assertIn("fixture-error", result.stderr)
        failed.unlink()
        self.run_cmd(["bash", str(runner)])
        self.assertEqual(self.run_cmd(["bash", str(runner), "--phase", "99"], check=False).returncode, 1)

    def test_smoke_test_starts_interactive_shell(self):
        for tool in ["spaceship", "mise", "git", "zoxide", "fzf", "bat", "lsd"]:
            self.stub(tool, "exit 0")
        self.write(self.home / ".zshrc", '''
PROMPT='fixture> '
typeset -A _comps
_comps[fixture]=fixture
fixture_widget() { :; }
zle -N atuin-search fixture_widget
bindkey '^R' atuin-search
zle -N autosuggest-accept fixture_widget
export LAST_SHELL_STARTUP_MS=1
zsh-defer() { [[ "$1" == -a ]] || return 1; shift; "$@"; }
''')
        self.write(self.home / ".config/sheldon/plugins.toml", "zsh-syntax-highlighting")
        smoke = (ROOT / "scripts/zsh-smoke-test").read_text().replace("~/.config", str(self.home / ".config"))
        path = self.write(self.home / "smoke.zsh", smoke)
        result = self.run_cmd(["zsh", str(path)])
        self.assertIn("Passed: 13", result.stdout)

    def test_sketchybar_follows_workspace_display_without_moving_workspaces(self):
        lua = shutil.which("lua") or shutil.which("luajit")
        if not lua:
            self.skipTest("lua or luajit required for SketchyBar fixture")
        fixture = self.write(self.home / "spaces-test.lua", '''
package.preload.colors = function() return {TEXT_WHITE=1,TEXT_GREY=2} end
package.preload["helpers.icon_map"] = function() return function() return "icon" end end
local display = "12"
local callbacks, states = {}, {}
io.popen = function(command)
  local result = ""
  if command == "aerospace list-workspaces --all" then result = "1\\n7"
  elseif command:find("--format", 1, true) then result = "1 1\\n7 " .. display
  elseif command:find("--focused", 1, true) then result = "7"
  elseif command == "aerospace list-monitors" then result = "1 main\\n2 secondary"
  elseif command:find("--monitor 1", 1, true) then result = "1"
  elseif command:find("list-windows", 1, true) then result = "1 | Terminal | shell" end
  return {read=function() return result end, close=function() end}
end
os.execute = function() error("must not move workspaces") end
sbar = {
  add=function() return {subscribe=function(_, event, callback) callbacks[event]=callback end} end,
  set=function(name, value) states[name]=value end,
  begin_config=function() end, end_config=function() end
}
dofile(arg[1])
assert(states["space.7"].display == "12")
display = "2"
callbacks.display_change()
assert(states["space.7"].display == "2")
''')
        self.run_cmd([lua, str(fixture), str(ROOT / "private_dot_config/sketchybar/items/spaces.lua")])
