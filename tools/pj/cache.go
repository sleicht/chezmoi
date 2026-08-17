package main

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

const cacheVersion = "pj-cache-v2"

// cacheFingerprint identifies configuration that affects project discovery.
func cacheFingerprint(cfg Config) string {
	hash := sha256.New()
	for _, dir := range cfg.Dirs {
		_, _ = fmt.Fprintln(hash, filepath.Clean(dir))
	}
	_, _ = fmt.Fprintln(hash, cfg.Depth)
	for _, exclude := range cfg.Excludes {
		_, _ = fmt.Fprintln(hash, exclude)
	}
	return hex.EncodeToString(hash.Sum(nil))
}

// loadCache reads cached project paths if the cache is current and matches cfg.
func loadCache(cfg Config) ([]string, bool) {
	info, err := os.Stat(cfg.CacheFile)
	if err != nil || time.Since(info.ModTime()) >= time.Duration(cfg.CacheTTL)*time.Second {
		return nil, false
	}

	f, err := os.Open(cfg.CacheFile)
	if err != nil {
		return nil, false
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	scanner.Buffer(make([]byte, 4096), 1024*1024)
	expectedHeader := cacheVersion + " " + cacheFingerprint(cfg)
	if !scanner.Scan() || scanner.Text() != expectedHeader {
		return nil, false
	}

	var paths []string
	for scanner.Scan() {
		if path := scanner.Text(); path != "" {
			paths = append(paths, path)
		}
	}
	if scanner.Err() != nil {
		return nil, false
	}
	return paths, true
}

// writeCache atomically persists project paths to disk.
func writeCache(cfg Config, paths []string) error {
	dir := filepath.Dir(cfg.CacheFile)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}

	f, err := os.CreateTemp(dir, ".cache-*")
	if err != nil {
		return err
	}
	tempPath := f.Name()
	defer os.Remove(tempPath)

	w := bufio.NewWriter(f)
	if _, err = fmt.Fprintln(w, cacheVersion+" "+cacheFingerprint(cfg)); err == nil {
		for _, path := range paths {
			if _, err = fmt.Fprintln(w, path); err != nil {
				break
			}
		}
	}
	if err == nil {
		err = w.Flush()
	}
	if closeErr := f.Close(); err == nil {
		err = closeErr
	}
	if err != nil {
		return err
	}
	return os.Rename(tempPath, cfg.CacheFile)
}
