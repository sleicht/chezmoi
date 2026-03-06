package main

import (
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

// projectMarkers are filenames that indicate a project root (non-git).
var projectMarkers = []string{
	"package.json", "go.mod", "Cargo.toml", "pom.xml",
	"Makefile", "build.gradle", "pyproject.toml",
}

// scanAll discovers repos under cfg.Dirs, collects metadata in parallel, and returns them.
func scanAll(cfg Config) []Repo {
	home, _ := os.UserHomeDir()
	excludeSet := make(map[string]bool, len(cfg.Excludes))
	for _, e := range cfg.Excludes {
		excludeSet[e] = true
	}

	// Phase 1: discover repo paths
	gitRepos := discoverGitRepos(cfg, excludeSet)
	markerRepos := discoverMarkerRepos(cfg, excludeSet)

	// Merge: marker repos only if they don't already have .git
	gitSet := make(map[string]bool, len(gitRepos))
	for _, p := range gitRepos {
		gitSet[p] = true
	}
	allPaths := append([]string{}, gitRepos...)
	for _, p := range markerRepos {
		if !gitSet[p] {
			allPaths = append(allPaths, p)
		}
	}

	// Prune nested repos (parent takes priority)
	sort.Strings(allPaths)
	var pruned []string
	var lastParent string
	for _, p := range allPaths {
		if lastParent != "" && strings.HasPrefix(p, lastParent+"/") {
			continue
		}
		pruned = append(pruned, p)
		lastParent = p
	}

	// Phase 2: collect metadata in parallel
	repos := make([]Repo, len(pruned))
	sem := make(chan struct{}, runtime.NumCPU())
	var wg sync.WaitGroup

	for i, path := range pruned {
		wg.Add(1)
		go func(idx int, repoPath string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			repos[idx] = collectMetadata(repoPath, home)
		}(i, path)
	}
	wg.Wait()

	// Filter out zero-value entries (shouldn't happen, but be safe)
	var result []Repo
	for _, r := range repos {
		if r.Path != "" {
			result = append(result, r)
		}
	}
	return result
}

// discoverGitRepos walks cfg.Dirs looking for .git directories.
func discoverGitRepos(cfg Config, excludes map[string]bool) []string {
	var paths []string
	maxDepth := cfg.Depth * 2 // .git can be one level deeper than the repo root

	for _, root := range cfg.Dirs {
		rootDepth := strings.Count(filepath.Clean(root), string(filepath.Separator))
		_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return fs.SkipDir
			}
			if !d.IsDir() {
				return nil
			}

			name := d.Name()

			// Skip excluded directories
			if excludes[name] && name != ".git" {
				return fs.SkipDir
			}

			// Depth check
			depth := strings.Count(filepath.Clean(path), string(filepath.Separator)) - rootDepth
			if depth > maxDepth {
				return fs.SkipDir
			}

			// Found a .git dir — record the parent as a repo
			if name == ".git" {
				paths = append(paths, filepath.Dir(path))
				return fs.SkipDir
			}
			return nil
		})
	}
	return paths
}

// discoverMarkerRepos walks cfg.Dirs looking for project marker files.
func discoverMarkerRepos(cfg Config, excludes map[string]bool) []string {
	markerSet := make(map[string]bool, len(projectMarkers))
	for _, m := range projectMarkers {
		markerSet[m] = true
	}

	seen := make(map[string]bool)
	for _, root := range cfg.Dirs {
		rootDepth := strings.Count(filepath.Clean(root), string(filepath.Separator))
		maxDepth := cfg.Depth * 2

		_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return fs.SkipDir
			}

			name := d.Name()
			if d.IsDir() {
				if excludes[name] {
					return fs.SkipDir
				}
				depth := strings.Count(filepath.Clean(path), string(filepath.Separator)) - rootDepth
				if depth > maxDepth {
					return fs.SkipDir
				}
				return nil
			}

			// Check if this file is a project marker
			if markerSet[name] {
				dir := filepath.Dir(path)
				seen[dir] = true
			}
			return nil
		})
	}

	paths := make([]string, 0, len(seen))
	for p := range seen {
		paths = append(paths, p)
	}
	return paths
}

// collectMetadata gathers git, mtime, and editor info for a single repo.
func collectMetadata(repoPath, home string) Repo {
	r := Repo{Path: repoPath}

	// Label: parent/name relative to home
	rel := strings.TrimPrefix(repoPath, home+"/")
	parent := filepath.Dir(rel)
	name := filepath.Base(rel)
	if parent == "." {
		r.Label = name
	} else {
		r.Label = parent + "/" + name
	}

	// Tilde path
	r.TildePath = "~/" + rel

	// Branch
	if out, err := exec.Command("git", "-C", repoPath, "branch", "--show-current").Output(); err == nil {
		r.Branch = strings.TrimSpace(string(out))
	}
	if r.Branch == "" {
		r.Branch = "(detached)"
	}

	// Dirty check (tracked files only, no untracked)
	if out, err := exec.Command("git", "-C", repoPath, "status", "--porcelain", "-uno").Output(); err == nil {
		if len(strings.TrimSpace(string(out))) > 0 {
			r.Dirty = true
		}
	}

	// Mtime + relative time
	if info, err := os.Stat(repoPath); err == nil {
		r.Mtime = info.ModTime().Unix()
		r.RelTime = relativeTime(info.ModTime())
	}

	// Editor detection
	r.EditorTag = detectEditor(repoPath)

	return r
}

// relativeTime formats a time as "Xm ago", "Xh ago", etc.
func relativeTime(t time.Time) string {
	delta := time.Since(t)
	switch {
	case delta < time.Hour:
		return strconv.Itoa(max(0, int(delta.Minutes()))) + "m ago"
	case delta < 24*time.Hour:
		return strconv.Itoa(int(delta.Hours())) + "h ago"
	case delta < 7*24*time.Hour:
		return strconv.Itoa(int(delta.Hours()/24)) + "d ago"
	default:
		return strconv.Itoa(int(delta.Hours()/(24*7))) + "w ago"
	}
}

// detectEditor checks for .idea/ and *.sublime-project files.
func detectEditor(repoPath string) string {
	ideaPath := filepath.Join(repoPath, ".idea")
	hasIdea := dirExists(ideaPath)

	sublimeFile := findSublimeProject(repoPath)
	hasSublime := sublimeFile != ""

	if hasIdea && hasSublime {
		ideaMtime := getMtime(ideaPath)
		sublimeMtime := getMtime(sublimeFile)
		if ideaMtime >= sublimeMtime {
			return "[IJ]"
		}
		return "[SL]"
	}
	if hasIdea {
		return "[IJ]"
	}
	if hasSublime {
		return "[SL]"
	}
	return ""
}

// findSublimeProject looks for *.sublime-project in the repo root (max depth 1).
func findSublimeProject(repoPath string) string {
	entries, err := os.ReadDir(repoPath)
	if err != nil {
		return ""
	}
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".sublime-project") {
			return filepath.Join(repoPath, e.Name())
		}
	}
	return ""
}

func dirExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func getMtime(path string) int64 {
	info, err := os.Stat(path)
	if err != nil {
		return 0
	}
	return info.ModTime().Unix()
}
