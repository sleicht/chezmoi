package main

import (
	"fmt"
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

// discoverAll finds project roots beneath configured directories.
func discoverAll(cfg Config) ([]string, error) {
	excludeSet := make(map[string]bool, len(cfg.Excludes))
	for _, exclude := range cfg.Excludes {
		excludeSet[strings.TrimSpace(exclude)] = true
	}

	gitRepos, err := discoverGitRepos(cfg, excludeSet)
	if err != nil {
		return nil, err
	}
	markerRepos, err := discoverMarkerRepos(cfg, excludeSet)
	if err != nil {
		return nil, err
	}

	allSet := make(map[string]bool, len(gitRepos)+len(markerRepos))
	for _, path := range append(gitRepos, markerRepos...) {
		allSet[filepath.Clean(path)] = true
	}
	allPaths := make([]string, 0, len(allSet))
	for path := range allSet {
		allPaths = append(allPaths, path)
	}
	sort.Strings(allPaths)

	pruned := make([]string, 0, len(allPaths))
	for _, path := range allPaths {
		nested := false
		for _, parent := range pruned {
			if isWithin(path, parent) {
				nested = true
				break
			}
		}
		if !nested {
			pruned = append(pruned, path)
		}
	}
	return pruned, nil
}

func isWithin(path, parent string) bool {
	rel, err := filepath.Rel(parent, path)
	return err == nil && rel != "." && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator))
}

func collectAllMetadata(paths []string) []Repo {
	home, _ := os.UserHomeDir()
	repos := make([]Repo, len(paths))
	sem := make(chan struct{}, max(1, runtime.NumCPU()))
	var wg sync.WaitGroup
	for i, path := range paths {
		wg.Add(1)
		go func(index int, repoPath string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			repos[index] = collectMetadata(repoPath, home)
		}(i, path)
	}
	wg.Wait()
	return repos
}

// discoverGitRepos walks cfg.Dirs looking for .git files and directories.
func discoverGitRepos(cfg Config, excludes map[string]bool) ([]string, error) {
	var paths []string
	for _, root := range cfg.Dirs {
		root = filepath.Clean(root)
		if _, err := os.Stat(root); err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return nil, fmt.Errorf("inspect project root %s: %w", root, err)
		}
		err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			depth, err := pathDepth(root, path)
			if err != nil {
				return err
			}
			if d.Name() == ".git" && depth-1 <= cfg.Depth {
				paths = append(paths, filepath.Dir(path))
				if d.IsDir() {
					return fs.SkipDir
				}
				return nil
			}
			if !d.IsDir() {
				return nil
			}
			if path != root && excludes[d.Name()] {
				return fs.SkipDir
			}
			if depth > cfg.Depth {
				return fs.SkipDir
			}
			return nil
		})
		if err != nil {
			return nil, fmt.Errorf("scan %s for Git repositories: %w", root, err)
		}
	}
	return paths, nil
}

func pathDepth(root, path string) (int, error) {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return 0, err
	}
	if rel == "." {
		return 0, nil
	}
	return len(strings.Split(rel, string(filepath.Separator))), nil
}

// discoverMarkerRepos walks cfg.Dirs looking for project marker files.
func discoverMarkerRepos(cfg Config, excludes map[string]bool) ([]string, error) {
	markerSet := make(map[string]bool, len(projectMarkers))
	for _, marker := range projectMarkers {
		markerSet[marker] = true
	}

	seen := make(map[string]bool)
	for _, root := range cfg.Dirs {
		root = filepath.Clean(root)
		if _, err := os.Stat(root); err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return nil, fmt.Errorf("inspect project root %s: %w", root, err)
		}
		err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			depth, err := pathDepth(root, path)
			if err != nil {
				return err
			}
			if d.IsDir() {
				if path != root && excludes[d.Name()] {
					return fs.SkipDir
				}
				if depth > cfg.Depth {
					return fs.SkipDir
				}
				return nil
			}
			if markerSet[d.Name()] && depth-1 <= cfg.Depth {
				seen[filepath.Dir(path)] = true
			}
			return nil
		})
		if err != nil {
			return nil, fmt.Errorf("scan %s for project markers: %w", root, err)
		}
	}

	paths := make([]string, 0, len(seen))
	for path := range seen {
		paths = append(paths, path)
	}
	return paths, nil
}

// collectMetadata gathers Git, activity, and editor information for one project.
func collectMetadata(repoPath, home string) Repo {
	r := Repo{Path: repoPath}

	rel, err := filepath.Rel(home, repoPath)
	if err != nil || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		rel = repoPath
	}
	parent := filepath.Dir(rel)
	name := filepath.Base(rel)
	if parent == "." {
		r.Label = name
	} else {
		r.Label = filepath.Join(parent, name)
	}
	if rel == repoPath {
		r.TildePath = repoPath
	} else {
		r.TildePath = "~/" + rel
	}

	isGit := false
	if out, err := exec.Command("git", "-C", repoPath, "rev-parse", "--is-inside-work-tree").Output(); err == nil {
		isGit = strings.TrimSpace(string(out)) == "true"
	}
	if isGit {
		if out, err := exec.Command("git", "-C", repoPath, "symbolic-ref", "--quiet", "--short", "HEAD").Output(); err == nil {
			r.Branch = strings.TrimSpace(string(out))
		} else {
			r.Branch = "(detached)"
		}
		if out, err := exec.Command("git", "-C", repoPath, "status", "--porcelain", "-uno").Output(); err == nil {
			r.Dirty = strings.TrimSpace(string(out)) != ""
		}
		if out, err := exec.Command("git", "-C", repoPath, "log", "-1", "--format=%ct").Output(); err == nil {
			r.Mtime, _ = strconv.ParseInt(strings.TrimSpace(string(out)), 10, 64)
		}
	}
	if r.Mtime == 0 {
		if info, err := os.Stat(repoPath); err == nil {
			r.Mtime = info.ModTime().Unix()
		}
	}
	if r.Mtime > 0 {
		r.RelTime = relativeTime(time.Unix(r.Mtime, 0))
	}
	r.EditorTag = detectEditor(repoPath)
	return r
}

// relativeTime formats a time as "Xm ago", "Xh ago", "Xd ago", "Xmo ago", or "Xy ago".
func relativeTime(t time.Time) string {
	delta := time.Since(t)
	hours := delta.Hours()
	switch {
	case delta < time.Hour:
		return strconv.Itoa(max(0, int(delta.Minutes()))) + "m ago"
	case hours < 24:
		return strconv.Itoa(int(hours)) + "h ago"
	case hours < 24*30:
		return strconv.Itoa(int(hours/24)) + "d ago"
	case hours < 24*365:
		return strconv.Itoa(int(hours/(24*30))) + "mo ago"
	default:
		return strconv.Itoa(int(hours/(24*365))) + "y ago"
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
