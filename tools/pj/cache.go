package main

import (
	"bufio"
	"os"
	"path/filepath"
	"time"
)

// loadCache reads the disk cache if it exists and is within TTL.
// Returns the lines and true if valid, or nil and false if stale/missing.
func loadCache(cfg Config) ([]string, bool) {
	info, err := os.Stat(cfg.CacheFile)
	if err != nil {
		return nil, false
	}

	age := time.Since(info.ModTime()).Seconds()
	if int64(age) >= cfg.CacheTTL {
		return nil, false
	}

	f, err := os.Open(cfg.CacheFile)
	if err != nil {
		return nil, false
	}
	defer f.Close()

	var lines []string
	scanner := bufio.NewScanner(f)
	// Increase buffer size for long display lines
	scanner.Buffer(make([]byte, 0, 4096), 4096)
	for scanner.Scan() {
		line := scanner.Text()
		if line != "" {
			lines = append(lines, line)
		}
	}
	if len(lines) == 0 {
		return nil, false
	}
	return lines, true
}

// writeCache persists cache lines to disk.
func writeCache(cfg Config, lines []string) {
	dir := filepath.Dir(cfg.CacheFile)
	_ = os.MkdirAll(dir, 0o755)

	f, err := os.Create(cfg.CacheFile)
	if err != nil {
		return
	}
	defer f.Close()

	w := bufio.NewWriter(f)
	for _, line := range lines {
		_, _ = w.WriteString(line)
		_ = w.WriteByte('\n')
	}
	_ = w.Flush()
}
