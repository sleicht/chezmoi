/**
 * Blocks direct gradle/gradlew calls when a project-level task runner exists.
 *
 * Ported from the Pi `mise-just-enforcer.ts` extension to an `omp` pre-tool hook.
 */
import { existsSync } from "node:fs";
import { join } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const GRADLE_PATTERN = /(?:^|[;&|]\s*|\n\s*)(?:\.\/)?gradlew?(?:\s|$)/m;

interface ToolCallEvent {
  toolName?: string;
  tool?: string;
  name?: string;
  input?: {
    command?: unknown;
  };
}

interface HookContext {
  cwd?: string;
  workingDirectory?: string;
}

interface TaskRunners {
  mise: string[] | null;
  just: string[] | null;
}

function toolName(event: ToolCallEvent) {
  return event.toolName ?? event.tool ?? event.name;
}

function commandInput(event: ToolCallEvent) {
  return typeof event.input?.command === "string" ? event.input.command : undefined;
}

async function listMiseTasks(cwd: string) {
  try {
    const { stdout } = await execFileAsync("mise", ["tasks", "--no-headers"], { cwd, timeout: 5000 });
    return stdout
      .split("\n")
      .map((line: string) => line.trim().split(/\s+/)[0] ?? "")
      .filter(Boolean);
  } catch {
    return [];
  }
}

async function listJustTargets(cwd: string) {
  try {
    const { stdout } = await execFileAsync("just", ["--list", "--list-prefix", ""], { cwd, timeout: 5000 });
    return stdout
      .split("\n")
      .slice(1)
      .map((line: string) => line.trim().split(/\s+/)[0] ?? "")
      .filter(Boolean);
  } catch {
    return [];
  }
}

async function detectTaskRunners(cwd: string): Promise<TaskRunners> {
  const hasMise =
    existsSync(join(cwd, "mise.toml")) ||
    existsSync(join(cwd, ".mise.toml")) ||
    existsSync(join(cwd, ".mise/config.toml"));

  const hasJust = existsSync(join(cwd, "justfile")) || existsSync(join(cwd, "Justfile"));

  return {
    mise: hasMise ? await listMiseTasks(cwd) : null,
    just: hasJust ? await listJustTargets(cwd) : null,
  };
}

function blockReason(command: string, { mise, just }: TaskRunners) {
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
      lines.push("→ Add a task to mise.toml rather than calling gradle directly.");
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

  lines.push("Only fall back to direct gradle/gradlew if no equivalent task exists.");
  return lines.join("\n");
}

export async function preTool(event: ToolCallEvent, context: HookContext = {}) {
  if (toolName(event) !== "bash") return undefined;

  const command = commandInput(event);
  if (!command || !GRADLE_PATTERN.test(command)) return undefined;

  const cwd = context.cwd ?? context.workingDirectory ?? process.cwd();
  const runners = await detectTaskRunners(cwd);

  if (runners.mise === null && runners.just === null) return undefined;

  return {
    block: true,
    reason: blockReason(command, runners),
  };
}

export default preTool;