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

// ANSI escape codes for colour output.
const (
	ansiReset   = "\033[0m"
	ansiGreen   = "\033[32m"
	ansiRed     = "\033[31m"
	ansiDim     = "\033[2m"
	ansiYellow  = "\033[33m"
	ansiCyan    = "\033[36m"
)

// truncate shortens s to maxLen, replacing the last char with '…' if truncated.
func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	if maxLen <= 1 {
		return "…"
	}
	return s[:maxLen-1] + "…"
}

// formatDisplay produces the coloured fixed-width display string for fzf.
// Layout: label(55) branch(25) time(8) editor(4)
func (r *Repo) formatDisplay() string {
	label := truncate(r.Label, 55)

	branch := r.Branch
	if r.Dirty {
		branch += "*"
	}
	padded := fmt.Sprintf("%-25s", truncate(branch, 25))
	// Colour the * red within the green branch
	var branchCol string
	if r.Dirty {
		idx := strings.LastIndex(padded, "*")
		branchCol = ansiGreen + padded[:idx] + ansiRed + "*" + ansiReset + padded[idx+1:]
	} else {
		branchCol = ansiGreen + padded + ansiReset
	}

	timeCol := ansiDim + fmt.Sprintf("%8s", r.RelTime) + ansiReset

	editorCol := ""
	if r.EditorTag != "" {
		editorCol = ansiCyan + r.EditorTag + ansiReset
	}

	return fmt.Sprintf("%-55s  %s  %s  %s", label, branchCol, timeCol, editorCol)
}

// formatCacheLine produces the "display\tpath" line for cache and fzf.
func (r *Repo) formatCacheLine() string {
	return r.formatDisplay() + "\t" + r.Path
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
