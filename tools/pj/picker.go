package main

import (
	"os"
	"os/exec"
	"strings"
)

// runPicker launches fzf in a loop (Ctrl+R triggers rescan).
// Returns the action ("cd", "editor", "cd+editor") and the selected path.
// Returns ("", "") on escape/no selection.
func runPicker(cfg Config, entries []string) (action, path string) {
	for {
		key, selected := launchFzf(entries)

		if key == "ctrl-r" {
			// Rescan, rebuild cache, relaunch
			repos := scanAll(cfg)
			entries = sortAndFormat(cfg, repos)
			writeCache(cfg, entries)
			continue
		}

		if selected == "" {
			return "", ""
		}

		// Extract path from "display\tpath" format
		if idx := strings.LastIndex(selected, "\t"); idx >= 0 {
			path = selected[idx+1:]
		} else {
			return "", ""
		}

		switch key {
		case "ctrl-e":
			return "editor", path
		case "ctrl-o":
			return "cd+editor", path
		default:
			return "cd", path
		}
	}
}

// launchFzf runs fzf as a subprocess and returns the pressed key and selected line.
func launchFzf(entries []string) (key, selected string) {
	input := strings.Join(entries, "\n")

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

	cmd.Stdin = strings.NewReader(input)
	cmd.Stderr = os.Stderr

	out, err := cmd.Output()
	if err != nil {
		// fzf returns exit code 1 on no match, 2 on error, 130 on interrupt
		return "", ""
	}

	lines := strings.SplitN(strings.TrimRight(string(out), "\n"), "\n", 2)
	if len(lines) == 0 {
		return "", ""
	}

	key = strings.TrimSpace(lines[0])
	if len(lines) > 1 {
		selected = strings.TrimSpace(lines[1])
	}

	return key, selected
}
