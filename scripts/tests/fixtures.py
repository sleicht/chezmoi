import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
CHEZMOI = shutil.which("chezmoi")


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        (self.home / "destination").mkdir()
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.env = {**os.environ, "PATH": f"{self.bin}:{os.environ['PATH']}",
                    "ZDOTDIR": str(self.home), "TERM": "xterm-256color"}
        # Fail closed: no fixture may access the real password manager.
        self.stub("rbw", 'echo unexpected-vault-access >&2; exit 91')

    def run_cmd(self, args, *, input=None, check=True, env=None):
        result = subprocess.run(args, input=input, text=True, capture_output=True,
                                cwd=self.home, env=env or self.env, timeout=45)
        if check:
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        return result

    def write(self, path, content):
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def stub(self, name, content):
        path = self.write(self.bin / name, "#!/bin/sh\n" + content + "\n")
        path.chmod(0o755)
        return path

    def data(self, machine="personal", os_name="darwin", arch="arm64"):
        return self.run_cmd(["jq", "-cn", "--arg", "machine", machine,
                             "--arg", "os", os_name, "--arg", "arch", arch,
                             "--arg", "home", str(self.home),
                             '{machine_type:$machine,chezmoi:{os:$os,arch:$arch,homeDir:$home}}']).stdout

    def chezmoi_args(self, machine="personal", os_name="darwin", arch="arm64", source=ROOT):
        return [CHEZMOI, "--config", "/dev/null", "--config-format", "yaml",
                "--source", str(source), "--destination", str(self.home / "destination"),
                "--cache", str(self.home / "cache"),
                "--persistent-state", str(self.home / "state.boltdb"),
                "--override-data", self.data(machine, os_name, arch)]

    def render(self, path, **kwargs):
        source = kwargs.get("source", ROOT)
        return self.run_cmd(self.chezmoi_args(**kwargs) +
                            ["execute-template", "--file", str(source / path)]).stdout

    def shell_home(self, content):
        return re.sub(r"\$\{HOME\}|\$HOME\b", str(self.home), content)

    def script(self, content, shell="bash", check=True):
        return self.run_cmd([shell, "-c", self.shell_home(content)], check=check)

    def synthetic_vault(self):
        self.stub("rbw", '''exec jq -cn --arg url "${FIXTURE_URL:-https://fixture.invalid}" '
{notes:"", fields:(["marketplace_name","marketplace_ref","marketplace_url",
"gitlab_domain","jira_domain","wiki_domain","brave_search_api_key"] |
map({name:.,value:"fixture",type:0})) + [{name:"litellm_url",value:$url,type:0}]}' ''')
