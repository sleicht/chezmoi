import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const WIDGET_ID = "git-status-widget";
const UPDATE_INTERVAL_MS = 2_000;

async function runGit(args: string[], cwd: string) {
	const { stdout } = await execFileAsync("git", args, {
		cwd,
		timeout: 2_000,
		maxBuffer: 1024 * 1024,
	});
	return stdout.trimEnd();
}

async function getBranch(cwd: string) {
	const branch = await runGit(["branch", "--show-current"], cwd);
	if (branch.length > 0) return branch;

	const head = await runGit(["rev-parse", "--short", "HEAD"], cwd);
	return head.length > 0 ? `detached@${head}` : "unknown";
}

function countUnstagedFiles(statusOutput: string) {
	if (statusOutput.length === 0) return 0;

	let count = 0;
	for (const line of statusOutput.split("\n")) {
		if (line.startsWith("??") || line[1] !== " ") count += 1;
	}
	return count;
}

async function getUnstagedCount(cwd: string) {
	const status = await runGit(
		["status", "--porcelain", "--untracked-files=normal"],
		cwd,
	);
	return countUnstagedFiles(status);
}

type SessionState = { closed: boolean };

function setWidget(
	ctx: ExtensionContext,
	state: SessionState,
	lines: string[] | undefined,
) {
	if (state.closed) return;

	try {
		if (ctx.hasUI) ctx.ui.setWidget(WIDGET_ID, lines);
	} catch {
		// Context may become stale during session replacement/reload.
	}
}

async function updateWidget(ctx: ExtensionContext, state: SessionState) {
	if (state.closed) return;

	let cwd: string;
	try {
		if (!ctx.hasUI) return;
		cwd = ctx.cwd;
	} catch {
		return;
	}

	try {
		await runGit(["rev-parse", "--is-inside-work-tree"], cwd);
		if (state.closed) return;

		const [branch, unstagedCount] = await Promise.all([
			getBranch(cwd),
			getUnstagedCount(cwd),
		]);
		if (state.closed) return;

		const fileLabel = unstagedCount === 1 ? "file" : "files";
		setWidget(ctx, state, [
			` ${branch} · ${unstagedCount} unstaged ${fileLabel}`,
		]);
	} catch {
		setWidget(ctx, state, undefined);
	}
}

export default function (pi: ExtensionAPI) {
	let interval: NodeJS.Timeout | undefined;
	let state: SessionState = { closed: true };

	pi.on("session_start", async (_event, ctx) => {
		if (interval) clearInterval(interval);
		state.closed = true;

		const currentState: SessionState = { closed: false };
		state = currentState;

		await updateWidget(ctx, currentState);
		interval = setInterval(() => {
			void updateWidget(ctx, currentState);
		}, UPDATE_INTERVAL_MS);
	});

	pi.on("input", async (_event, ctx) => {
		await updateWidget(ctx, state);
		return { action: "continue" };
	});

	pi.on("tool_execution_end", async (_event, ctx) => {
		await updateWidget(ctx, state);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		state.closed = true;
		if (interval) {
			clearInterval(interval);
			interval = undefined;
		}
		setWidget(ctx, { closed: false }, undefined);
	});
}
