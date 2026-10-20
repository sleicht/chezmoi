import tomllib
from fixtures import Fixture, ROOT


class ProfileTests(Fixture):
    def test_non_client_templates_do_not_read_work_vault(self):
        for machine in ["personal", "server", "container"]:
            for path in ["dot_zsh.d/functions.zsh.tmpl", ".chezmoitemplates/codex-config.toml.tmpl"]:
                with self.subTest(machine=machine, path=path):
                    content = self.render(path, machine=machine)
                    if "toml" in path:
                        self.assertNotIn("model_provider", tomllib.loads(content))

    def test_container_only_manages_basic_shell_and_git_files(self):
        args = self.chezmoi_args(machine="container", os_name="linux", arch="amd64")
        managed = set(self.run_cmd(args + ["managed", "--path-style", "relative"]).stdout.splitlines())
        expected = {".profile", ".bash_profile", ".zshenv", ".zprofile", ".zshrc", ".zlogin",
                    ".inputrc", ".gitconfig", ".gitignore_global", ".gitattributes_global", ".editorconfig", ".hushlogin"}
        self.assertEqual(managed, expected)
        self.run_cmd(args + ["apply", "--force"])
        destination = self.home / "destination"
        profile = self.shell_home((destination / ".profile").read_text())
        self.write(self.home / ".profile", profile)
        rc = self.shell_home((destination / ".zshrc").read_text())
        result = self.script(rc + '\n(( $+_comps )) && [[ -n "$PROMPT" ]]', shell="zsh")
        self.assertNotIn("command not found", result.stderr)
        self.assertNotIn("hooksPath", (destination / ".gitconfig").read_text())

    def test_server_claude_settings_are_valid_json(self):
        self.synthetic_vault()
        for machine in ["client", "personal", "server", "container"]:
            with self.subTest(machine=machine):
                content = self.render(".chezmoitemplates/claude-settings.json.tmpl", machine=machine)
                self.run_cmd(["jq", "-e", '.extraKnownMarketplaces | has("plannotator")'], input=content)
        codex = tomllib.loads(self.render(".chezmoitemplates/codex-config.toml.tmpl", machine="client"))
        self.assertEqual(codex["model_providers"]["litellm"]["base_url"], "https://fixture.invalid/v1")

    def test_homebrew_prefix_matches_platform(self):
        self.env.pop("HOMEBREW_PREFIX", None)
        for arch, prefix in [("amd64", "/usr/local"), ("arm64", "/opt/homebrew")]:
            with self.subTest(arch=arch):
                plugins = self.render("dot_zsh_plugins.txt.tmpl", arch=arch)
                self.assertIn(f"{prefix}/share/forgit path:forgit.plugin.zsh", plugins)
                self.assertIn(f"{prefix}/share/zsh-abbr path:zsh-abbr.zsh", plugins)
        profile = self.render("dot_profile.tmpl", os_name="linux", arch="amd64")
        result = self.script(profile + '\nprintf "%s" "$HOMEBREW_PREFIX"', shell="sh")
        self.assertEqual(result.stdout, "/home/linuxbrew/.linuxbrew")

    def test_zshrc_loads_antidote_and_tolerates_missing_install(self):
        self.write(self.home / ".profile", "")
        rc = self.render("dot_zshrc.tmpl")
        self.env["HOMEBREW_PREFIX"] = str(self.home / "missing")
        result = self.script(rc, shell="zsh")
        self.assertNotIn("antidote", result.stderr)
        prefix = self.home / "brew"
        self.write(prefix / "opt/antidote/share/antidote/antidote.zsh",
                   'antidote() { [[ "$1" == load ]] && export ANTIDOTE_FIXTURE=ok; }')
        self.env["HOMEBREW_PREFIX"] = str(prefix)
        result = self.script(rc + '\nprintf "%s" "$ANTIDOTE_FIXTURE"', shell="zsh")
        self.assertEqual(result.stdout, "ok")
