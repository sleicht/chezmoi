/**
 * Mise/Just Enforcer Extension
 *
 * Intercepts direct gradle/gradlew calls and redirects the LLM to use
 * `mise run` or `just` when a task runner is available in the project.
 *
 * Detection:
 *   - mise.toml / .mise.toml / .mise/config.toml  → `mise run <task>`
 *   - justfile / Justfile                          → `just <target>`
 *
 * On a match the tool call is blocked and the LLM receives a list of
 * available tasks so it can immediately retry with the right command.
 * Direct gradle is only allowed when neither runner is present.
 */
import { existsSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Matches gradle or ./gradlew at the start of a statement (incl. multi-line scripts). */
const GRADLE_PATTERN = /(?:^|[;&|]\s*|\n\s*)(?:\.\/)?gradlew?(?:\s|$)/m;

interface TaskRunners {
	/** null = no mise config found; string[] = tasks (may be empty) */
	mise: string[] | null;
	/** null = no justfile found; string[] = targets (may be empty) */
	just: string[] | null;
}

async function detectTaskRunners(
	cwd: string,
	pi: ExtensionAPI,
): Promise<TaskRunners> {
	const hasMise =
		existsSync(join(cwd, "mise.toml")) ||
		existsSync(join(cwd, ".mise.toml")) ||
		existsSync(join(cwd, ".mise/config.toml"));

	const hasJust =
		existsSync(join(cwd, "justfile")) || existsSync(join(cwd, "Justfile"));

	let mise: string[] | null = null;
	let just: string[] | null = null;

	if (hasMise) {
		try {
			const res = await pi.exec("mise", ["tasks", "--no-headers"], {
				timeout: 5000,
			});
			mise = res.stdout
				.split("\n")
				.map((l) => l.trim().split(/\s+/)[0] ?? "")
				.filter(Boolean);
		} catch {
			mise = []; // config exists but tasks unavailable / mise not on PATH
		}
	}

	if (hasJust) {
		try {
			const res = await pi.exec("just", ["--list", "--list-prefix", ""], {
				timeout: 5000,
			});
			just = res.stdout
				.split("\n")
				.slice(1) // skip "Available recipes:" header
				.map((l) => l.trim().split(/\s+/)[0] ?? "")
				.filter(Boolean);
		} catch {
			just = []; // justfile exists but just not on PATH
		}
	}

	return { mise, just };
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;
		if (!GRADLE_PATTERN.test(command)) return undefined;

		const { mise, just } = await detectTaskRunners(ctx.cwd, pi);

		// No task runner present — let gradle proceed as-is.
		if (mise === null && just === null) return undefined;

		const lines: string[] = [
			"Direct gradle/gradlew call blocked — use the project task runner instead.",
			"",
			`Command attempted: \`${command.trim()}\``,
			"",
		];

		if (mise !== null) {
			if (mise.length > 0) {
				lines.push(`mise tasks available:  ${mise.join("  ")}`);
				lines.push("→ Use: mise run <task>");
			} else {
				lines.push("mise config found (no tasks defined yet).");
				lines.push(
					"→ Add a task to mise.toml rather than calling gradle directly.",
				);
			}
			lines.push("");
		}

		if (just !== null) {
			if (just.length > 0) {
				lines.push(`just targets available:  ${just.join("  ")}`);
				lines.push("→ Use: just <target>");
			} else {
				lines.push("justfile found (no targets defined yet).");
			}
			lines.push("");
		}

		lines.push(
			"Only fall back to direct gradle/gradlew if no equivalent task exists.",
		);

		return { block: true, reason: lines.join("\n") };
	});
}
