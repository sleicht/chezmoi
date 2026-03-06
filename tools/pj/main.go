package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// Config holds all runtime configuration parsed from environment variables.
type Config struct {
	Dirs     []string
	Depth    int
	Excludes []string
	CacheTTL int64 // seconds
	CacheFile string
}

func parseConfig() Config {
	home, _ := os.UserHomeDir()

	dirs := []string{filepath.Join(home, "Projects"), filepath.Join(home, "git")}
	if env := os.Getenv("PJ_DIRS"); env != "" {
		dirs = nil
		for _, d := range strings.Split(env, ":") {
			d = strings.TrimSpace(d)
			if d == "" {
				continue
			}
			// Expand ~ prefix
			if strings.HasPrefix(d, "~/") {
				d = filepath.Join(home, d[2:])
			}
			dirs = append(dirs, d)
		}
	}

	depth := 2
	if env := os.Getenv("PJ_DEPTH"); env != "" {
		if v, err := strconv.Atoi(env); err == nil && v > 0 {
			depth = v
		}
	}

	excludes := []string{"node_modules", ".cache", "vendor", "target", "build", "dist", "__pycache__"}
	if env := os.Getenv("PJ_EXCLUDES"); env != "" {
		excludes = strings.Split(env, ":")
	}

	cacheTTL := int64(604800) // 1 week
	if env := os.Getenv("PJ_CACHE_TTL"); env != "" {
		if v, err := strconv.ParseInt(env, 10, 64); err == nil && v > 0 {
			cacheTTL = v
		}
	}

	cacheDir := os.Getenv("XDG_CACHE_HOME")
	if cacheDir == "" {
		cacheDir = filepath.Join(home, ".cache")
	}
	cacheFile := filepath.Join(cacheDir, "pj", "cache")

	return Config{
		Dirs:      dirs,
		Depth:     depth,
		Excludes:  excludes,
		CacheTTL:  cacheTTL,
		CacheFile: cacheFile,
	}
}

// Repo holds discovered repository metadata.
type Repo struct {
	Path       string
	Label      string // parent/name display label
	Branch     string
	Dirty      bool
	TildePath  string
	RelTime    string
	Mtime      int64
	EditorTag  string // "[IJ]", "[SL]", or ""
}

// formatDisplay produces the fixed-width display string for fzf.
func (r *Repo) formatDisplay() string {
	branch := r.Branch
	if r.Dirty {
		branch += "*"
	}
	return fmt.Sprintf("%-35s  %-22s  %-45s  %-8s  %s",
		r.Label, branch, r.TildePath, r.RelTime, r.EditorTag)
}

// formatCacheLine produces the "display|path" line for cache and fzf.
func (r *Repo) formatCacheLine() string {
	return r.formatDisplay() + "|" + r.Path
}

func main() {
	cfg := parseConfig()

	// Try loading from disk cache
	entries, ok := loadCache(cfg)
	if !ok {
		repos := scanAll(cfg)
		entries = sortAndFormat(cfg, repos)
		writeCache(cfg, entries)
	}

	// Run fzf picker loop (handles Ctrl+R internally)
	action, path := runPicker(cfg, entries)
	if action == "" || path == "" {
		return
	}

	// Output protocol: "action\tpath"
	fmt.Printf("%s\t%s\n", action, path)
}

// sortAndFormat applies zoxide ordering + mtime fallback, returns cache lines.
func sortAndFormat(cfg Config, repos []Repo) []string {
	zScores := queryZoxide(cfg)

	// Build path→repo index
	repoMap := make(map[string]*Repo, len(repos))
	for i := range repos {
		repoMap[repos[i].Path] = &repos[i]
	}

	var lines []string
	seen := make(map[string]bool, len(repos))

	// Zoxide-ordered first
	for _, zr := range zScores {
		if r, ok := repoMap[zr.Path]; ok && !seen[r.Path] {
			lines = append(lines, r.formatCacheLine())
			seen[r.Path] = true
		}
	}

	// Remaining by mtime descending
	remaining := make([]Repo, 0, len(repos))
	for i := range repos {
		if !seen[repos[i].Path] {
			remaining = append(remaining, repos[i])
		}
	}
	sort.Slice(remaining, func(i, j int) bool {
		return remaining[i].Mtime > remaining[j].Mtime
	})
	for _, r := range remaining {
		lines = append(lines, r.formatCacheLine())
	}

	return lines
}
