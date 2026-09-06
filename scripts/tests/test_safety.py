import shutil
from fixtures import Fixture, ROOT


class SafetyTests(Fixture):
    def test_permissions_repair_every_file_on_both_bash_versions(self):
        script = self.render("run_after_10-verify-permissions.sh.tmpl")
        for shell in dict.fromkeys(["/bin/bash", shutil.which("bash")]):
            with self.subTest(shell=shell):
                files = [self.write(self.home / name, "fixture") for name in [".netrc", ".git-credentials"]]
                for file in files:
                    file.chmod(0o644)
                self.script(script, shell=shell)
                self.assertEqual([file.stat().st_mode & 0o777 for file in files], [0o600, 0o600])

    def test_skill_sync_preserves_independent_skills_and_every_archive(self):
        script = self.render("run_after_11-sync-plugin-skills.sh.tmpl")
        source = self.home / ".claude/skills"
        target = self.home / ".agents/skills"
        independent = self.write(target / "independent/SKILL.md", "keep me")
        self.write(source / "independent/SKILL.md", "do not overwrite")
        self.write(target / ".archive/managed/SKILL.md", "old archive")
        for version in ["one", "two"]:
            self.write(source / "managed/SKILL.md", version)
            self.script(script)
            self.assertEqual((target / "managed/SKILL.md").read_text(), version)
            self.write(source / "managed/SKILL.md", version + " updated")
            self.script(script)
            self.assertEqual((target / "managed/SKILL.md").read_text(), version + " updated")
            shutil.rmtree(source / "managed")
            self.script(script)
            self.assertFalse((target / "managed").exists())
        self.assertEqual(independent.read_text(), "keep me")
        self.assertEqual(len(list((target / ".archive").glob("*/managed/SKILL.md"))), 2)
        self.assertEqual((target / ".archive/managed/SKILL.md").read_text(), "old archive")

    def test_malformed_plugin_metadata_cannot_archive_skills(self):
        script = self.render("run_after_11-sync-plugin-skills.sh.tmpl")
        marker = self.write(self.home / ".agents/skills/owned/.chezmoi-skill-sync", "")
        (self.home / ".claude/plugins/cache").mkdir(parents=True)
        self.write(self.home / ".claude/plugins/installed_plugins.json", "invalid")
        self.assertNotEqual(self.script(script, check=False).returncode, 0)
        self.assertTrue(marker.exists())

    def test_push_scans_outgoing_commits_and_blocks_scan_failure(self):
        self.stub("git", 'case "$1" in rev-parse) echo repo;; cat-file) exit 0;; esac')
        self.stub("gitleaks", 'printf "%s\\n" "$*" >> scan-args; exit "${SCAN_STATUS:-0}"')
        hook = ROOT / "private_dot_config/git/hooks/executable_pre-push"
        updates = "refs/heads/main abc refs/heads/main def\nrefs/heads/new 123 refs/heads/new 000\nrefs/heads/gone 000 refs/heads/gone 789\n"
        self.run_cmd(["bash", str(hook)], input=updates)
        calls = (self.home / "scan-args").read_text().splitlines()
        self.assertEqual(calls, ["git --log-opts=def..abc --redact --verbose",
                                 "git --log-opts=123 --redact --verbose"])
        self.env["SCAN_STATUS"] = "1"
        self.assertNotEqual(self.run_cmd(["bash", str(hook)], input=updates, check=False).returncode, 0)

    def test_checkout_dispatch_does_not_change_shared_hooks(self):
        self.stub("git", 'echo repo')
        local = self.write(self.home / "repo/hooks/post-checkout", '#!/bin/sh\nprintf "%s\\n" "$@" > received\nexit 7\n')
        local.chmod(0o755)
        hook = ROOT / "private_dot_config/git/hooks/executable_post-checkout"
        shared = self.write(self.home / "shared/post-checkout", hook.read_text())
        sentinel = self.write(self.home / "shared/pre-commit", "keep")
        result = self.run_cmd(["sh", str(shared), "old", "new", "1"], check=False)
        self.assertEqual(result.returncode, 7)
        self.assertEqual((self.home / "received").read_text(), "old\nnew\n1\n")
        self.assertEqual(sentinel.read_text(), "keep")
        self.assertTrue(shared.exists())
