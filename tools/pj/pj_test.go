package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"unicode/utf8"
)

func TestDiscoverAllHonoursDepth(t *testing.T) {
	root := t.TempDir()
	atLimit := filepath.Join(root, "group", "project")
	tooDeep := filepath.Join(root, "group", "nested", "project")
	for _, path := range []string{atLimit, tooDeep} {
		if err := os.MkdirAll(filepath.Join(path, ".git"), 0o755); err != nil {
			t.Fatal(err)
		}
	}

	paths, err := discoverAll(Config{Dirs: []string{root}, Depth: 2})
	if err != nil {
		t.Fatal(err)
	}
	if len(paths) != 1 || paths[0] != atLimit {
		t.Fatalf("paths = %v, want [%s]", paths, atLimit)
	}
}

func TestDiscoverAllSkipsMissingRoots(t *testing.T) {
	root := t.TempDir()
	project := filepath.Join(root, "project")
	if err := os.MkdirAll(project, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(project, "go.mod"), []byte("module example\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	paths, err := discoverAll(Config{Dirs: []string{filepath.Join(root, "missing"), root}, Depth: 1})
	if err != nil {
		t.Fatal(err)
	}
	if len(paths) != 1 || paths[0] != project {
		t.Fatalf("paths = %v, want [%s]", paths, project)
	}
}

func TestCollectMetadataDistinguishesProjectTypes(t *testing.T) {
	requireCommand(t, "git")
	root := t.TempDir()
	plain := filepath.Join(root, "plain")
	attached := filepath.Join(root, "attached")
	detached := filepath.Join(root, "detached")
	if err := os.MkdirAll(plain, 0o755); err != nil {
		t.Fatal(err)
	}
	initGitRepo(t, attached, false)
	initGitRepo(t, detached, true)

	if got := collectMetadata(plain, root).Branch; got != "" {
		t.Fatalf("plain project branch = %q, want empty", got)
	}
	if got := collectMetadata(attached, root).Branch; got == "" || got == "(detached)" {
		t.Fatalf("attached branch = %q", got)
	}
	if got := collectMetadata(detached, root).Branch; got != "(detached)" {
		t.Fatalf("detached branch = %q", got)
	}
}

func TestCollectMetadataUsesLatestCommitTime(t *testing.T) {
	requireCommand(t, "git")
	repo := filepath.Join(t.TempDir(), "repo")
	initGitRepo(t, repo, false)

	out, err := exec.Command("git", "-C", repo, "log", "-1", "--format=%ct").Output()
	if err != nil {
		t.Fatal(err)
	}
	want := strings.TrimSpace(string(out))
	got := collectMetadata(repo, filepath.Dir(repo))
	if want != strconv.FormatInt(got.Mtime, 10) {
		t.Fatalf("activity time = %d, want %s", got.Mtime, want)
	}
}

func TestCacheRejectsConfigChangeAndCorruption(t *testing.T) {
	cacheFile := filepath.Join(t.TempDir(), "cache")
	cfg := Config{Dirs: []string{"/projects"}, Depth: 2, Excludes: []string{"build"}, CacheTTL: 60, CacheFile: cacheFile}
	paths := []string{"/projects/example"}
	if err := writeCache(cfg, paths); err != nil {
		t.Fatal(err)
	}
	if got, ok := loadCache(cfg); !ok || len(got) != 1 || got[0] != paths[0] {
		t.Fatalf("loadCache() = %v, %v", got, ok)
	}

	changed := cfg
	changed.Depth++
	if _, ok := loadCache(changed); ok {
		t.Fatal("cache accepted changed discovery configuration")
	}

	corrupt := cacheVersion + " " + cacheFingerprint(cfg) + "\n" + strings.Repeat("x", 1024*1024+1)
	if err := os.WriteFile(cacheFile, []byte(corrupt), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, ok := loadCache(cfg); ok {
		t.Fatal("cache accepted an overlong, corrupt record")
	}
}

func TestCacheStoresEmptyScan(t *testing.T) {
	cfg := Config{Dirs: []string{"/projects"}, Depth: 2, CacheTTL: 60, CacheFile: filepath.Join(t.TempDir(), "cache")}
	if err := writeCache(cfg, nil); err != nil {
		t.Fatal(err)
	}
	paths, ok := loadCache(cfg)
	if !ok || len(paths) != 0 {
		t.Fatalf("loadCache() = %v, %v; want empty valid cache", paths, ok)
	}
}

func TestRunContinuesWhenCacheIsReadOnly(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("read-only directory semantics differ on Windows")
	}
	root := t.TempDir()
	project := filepath.Join(root, "project")
	if err := os.MkdirAll(project, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(project, "go.mod"), []byte("module example\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	cacheDir := filepath.Join(root, "cache")
	if err := os.Mkdir(cacheDir, 0o500); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PJ_DIRS", root)
	t.Setenv("PJ_DEPTH", "1")
	t.Setenv("XDG_CACHE_HOME", cacheDir)
	binDir := t.TempDir()
	writeExecutable(t, filepath.Join(binDir, "fzf"), "#!/bin/sh\nexit 1\n")
	t.Setenv("PATH", binDir)
	if err := run(); err != nil {
		t.Fatalf("run() failed because cache was read-only: %v", err)
	}
}

func TestLaunchFzfExitHandling(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("test helper uses a POSIX shell script")
	}
	binDir := t.TempDir()
	fzf := filepath.Join(binDir, "fzf")
	t.Setenv("PATH", binDir)

	writeExecutable(t, fzf, "#!/bin/sh\nexit 1\n")
	if _, _, err := launchFzf(nil); err != nil {
		t.Fatalf("cancellation returned error: %v", err)
	}

	writeExecutable(t, fzf, "#!/bin/sh\nexit 2\n")
	if _, _, err := launchFzf(nil); err == nil {
		t.Fatal("fzf failure was treated as cancellation")
	}
}

func TestTruncatePreservesUTF8(t *testing.T) {
	got := truncate("ab😊cd", 4)
	if got != "ab😊…" {
		t.Fatalf("truncate() = %q", got)
	}
	if !utf8.ValidString(got) {
		t.Fatalf("truncate() returned invalid UTF-8: %q", got)
	}
}

func initGitRepo(t *testing.T, path string, detached bool) {
	t.Helper()
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatal(err)
	}
	runCommand(t, path, "git", "init", "-q")
	runCommand(t, path, "git", "config", "user.name", "Test")
	runCommand(t, path, "git", "config", "user.email", "test@example.invalid")
	runCommand(t, path, "git", "config", "commit.gpgsign", "false")
	runCommand(t, path, "git", "config", "core.hooksPath", filepath.Join(path, ".git", "test-hooks"))
	if err := os.WriteFile(filepath.Join(path, "README"), []byte("test\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	runCommand(t, path, "git", "add", "README")
	cmd := exec.Command("git", "commit", "-qm", "initial")
	cmd.Dir = path
	cmd.Env = append(os.Environ(), "GIT_AUTHOR_DATE=2001-02-03T04:05:06Z", "GIT_COMMITTER_DATE=2001-02-03T04:05:06Z")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("git commit: %v: %s", err, out)
	}
	if detached {
		runCommand(t, path, "git", "checkout", "-q", "--detach")
	}
}

func runCommand(t *testing.T, dir, name string, args ...string) {
	t.Helper()
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("%s %v: %v: %s", name, args, err, out)
	}
}

func requireCommand(t *testing.T, name string) {
	t.Helper()
	if _, err := exec.LookPath(name); err != nil {
		t.Skipf("%s unavailable", name)
	}
}

func writeExecutable(t *testing.T, path, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0o755); err != nil {
		t.Fatal(err)
	}
}
