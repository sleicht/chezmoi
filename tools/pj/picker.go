package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// runPicker launches fzf in a loop; Ctrl+R rescans project paths.
func runPicker(cfg Config, entries []string) (action, path string, err error) {
	for {
		key, selected, err := launchFzf(entries)
		if err != nil {
			return "", "", err
		}

		if key == "ctrl-r" {
			paths, err := discoverAll(cfg)
			if err != nil {
				return "", "", err
			}
			_ = writeCache(cfg, paths)
			entries = sortAndFormat(cfg, collectAllMetadata(paths))
			continue
		}

		if selected == "" {
			return "", "", nil
		}

		if idx := strings.LastIndex(selected, "\t"); idx >= 0 {
			path = selected[idx+1:]
		} else {
			return "", "", fmt.Errorf("invalid fzf selection")
		}

		switch key {
		case "ctrl-e":
			return "editor", path, nil
		case "ctrl-o":
			return "cd+editor", path, nil
		default:
			return "cd", path, nil
		}
	}
}

// launchFzf runs fzf and distinguishes cancellation from execution failures.
func launchFzf(entries []string) (key, selected string, err error) {
	cmd := exec.Command("fzf",
		"--expect=ctrl-e,ctrl-o,ctrl-r",
		"--ansi",
		"--delimiter=\t",
		"--with-nth=1",
		"--preview=git -C {2} log --oneline --graph --color=always -15 2>/dev/null",
		"--preview-window=bottom,40%,border-rounded",
		"--header=Enter: cd  |  Ctrl+E: editor  |  Ctrl+O: cd+editor  |  Ctrl+R: refresh",
		"--layout=reverse-list",
	)

	cmd.Stdin = strings.NewReader(strings.Join(entries, "\n"))
	cmd.Stderr = os.Stderr

	out, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && (exitErr.ExitCode() == 1 || exitErr.ExitCode() == 130) {
			return "", "", nil
		}
		return "", "", fmt.Errorf("run fzf: %w", err)
	}

	lines := strings.SplitN(strings.TrimSuffix(string(out), "\n"), "\n", 2)
	if len(lines) == 0 {
		return "", "", nil
	}
	key = strings.TrimSpace(lines[0])
	if len(lines) > 1 {
		selected = strings.TrimSuffix(lines[1], "\r")
	}
	return key, selected, nil
}
