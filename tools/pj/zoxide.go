package main

import (
	"os/exec"
	"strconv"
	"strings"
)

// ZoxideResult holds a path and its frecency score.
type ZoxideResult struct {
	Score float64
	Path  string
}

// queryZoxide runs `zoxide query --list --score` and filters results to paths
// under cfg.Dirs. Results are returned in zoxide's frecency order (highest first).
func queryZoxide(cfg Config) []ZoxideResult {
	out, err := exec.Command("zoxide", "query", "--list", "--score").Output()
	if err != nil {
		return nil
	}

	dirPrefixes := make([]string, len(cfg.Dirs))
	for i, d := range cfg.Dirs {
		dirPrefixes[i] = d + "/"
	}

	var results []ZoxideResult
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// Format: "  123.4 /path/to/dir"
		parts := strings.SplitN(line, " ", 2)
		if len(parts) < 2 {
			continue
		}
		scoreStr := strings.TrimSpace(parts[0])
		path := strings.TrimSpace(parts[1])

		score, err := strconv.ParseFloat(scoreStr, 64)
		if err != nil {
			continue
		}

		// Filter to paths under PJ_DIRS
		inScope := false
		for _, prefix := range dirPrefixes {
			if strings.HasPrefix(path, prefix) {
				inScope = true
				break
			}
		}
		if !inScope {
			continue
		}

		results = append(results, ZoxideResult{Score: score, Path: path})
	}

	return results
}
