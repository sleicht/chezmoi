type PermissionDecision = "allow" | "ask" | "deny";

interface ToolExecuteInput {
	tool?: string;
}

interface ToolExecuteOutput {
	args?: unknown;
}

interface DecisionResult {
	decision: PermissionDecision;
	reason: string;
}

interface CacheEntry extends DecisionResult {
	expiresAt: number;
}

const REVIEWED_TOOLS: Record<string, true> = {
	shell: true,
	write: true,
	patch: true,
	multi_patch: true,
	remove: true,
	fetch: true,
	task: true,
};

const LOW_RISK_TOOLS: Record<string, true> = {
	read: true,
	fs_search: true,
	todo_read: true,
	todo_write: true,
	skill: true,
	undo: true,
};

const HARD_BLOCK_PATTERNS: Record<string, Array<{ pattern: RegExp; reason: string }>> = {
	shell: [
		{ pattern: /\bsudo\b/i, reason: "sudo commands require explicit approval" },
		{ pattern: /\brm\s+(-rf?|--recursive)\s+(\/|~)/i, reason: "Destructive removal of root or home directory" },
		{ pattern: /\bmkfs\b/i, reason: "Disk formatting is not allowed" },
		{ pattern: /\bdd\s+.*of=\/dev\//i, reason: "Direct disk writes are not allowed" },
		{ pattern: /\b(chmod|chown)\b.*777/i, reason: "Overly permissive file permissions" },
		{ pattern: /\bchown\b.*\/(etc|usr|var|sys|proc)/i, reason: "Cannot change ownership of system directories" },
		{ pattern: /\bkill\s+-9\b.*(init|systemd|1\b)/i, reason: "Cannot kill system processes" },
	],
	write: [{ pattern: /(\/etc\/|\/usr\/|\/var\/|\/sys\/|\/proc\/)/i, reason: "Cannot write to system directories" }],
	patch: [{ pattern: /(\/etc\/|\/usr\/|\/var\/|\/sys\/|\/proc\/)/i, reason: "Cannot edit system configuration files" }],
	multi_patch: [{ pattern: /(\/etc\/|\/usr\/|\/var\/|\/sys\/|\/proc\/)/i, reason: "Cannot edit system configuration files" }],
	remove: [{ pattern: /(\/etc\/|\/usr\/|\/var\/|\/sys\/|\/proc\/)/i, reason: "Cannot remove system files" }],
};

const DEFAULT_MODEL = "claude-haiku-4-5";
const TIMEOUT_MS = 10_000;
const CACHE_TTL_MS = 60 * 60 * 1000;
const MAX_CACHE_SIZE = 500;
const DIRECT_QUESTION_PATTERN = new RegExp("ask[_-]?user|Ask" + "User" + "Question", "i");

const decisionCache = new Map<string, CacheEntry>();

function isRecord(value: unknown): value is Record<string, unknown> {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}

function stableStringify(value: unknown): string {
	if (value === null || typeof value !== "object") return JSON.stringify(value);
	if (Array.isArray(value)) return `[${value.map(stableStringify).join(",")}]`;

	return `{${Object.keys(value)
		.sort()
		.map((key) => `${JSON.stringify(key)}:${stableStringify((value as Record<string, unknown>)[key])}`)
		.join(",")}}`;
}

function isDirectQuestionToUser(event: { toolName?: string; input?: unknown }): boolean {
	if (event.toolName !== undefined && DIRECT_QUESTION_PATTERN.test(event.toolName)) return true;

	try {
		return DIRECT_QUESTION_PATTERN.test(JSON.stringify(event.input));
	} catch {
		return false;
	}
}


function checkHardBlock(event: { toolName?: string; input?: unknown }): string | undefined {
	if (event.toolName === undefined) return;

	const patterns = HARD_BLOCK_PATTERNS[event.toolName];
	if (patterns === undefined) return;

	const input = stableStringify(event.input);
	return patterns.find(({ pattern }) => pattern.test(input))?.reason;
}

function renderOperation(toolName: string | undefined, input: unknown): string {
	if (toolName === undefined) return "unknown";
	if (toolName === "shell" && isRecord(input) && typeof input.command === "string") return `shell: ${input.command}`;
	if (!isRecord(input)) return `${toolName}: ${JSON.stringify(input)}`;

	const entries = Object.entries(input);
	if (entries.length === 0) return toolName;

	return `${toolName}: ${entries.map(([key, value]) => `${key}=${typeof value === "string" ? value : JSON.stringify(value)}`).join(", ")}`;
}

function parseDecision(content: string): DecisionResult {
	try {
		const parsed = JSON.parse(content) as { decision?: unknown; reason?: unknown };
		const decision = parsed.decision;
		if (decision === "allow" || decision === "ask" || decision === "deny") {
			return {
				decision,
				reason: typeof parsed.reason === "string" && parsed.reason.trim() ? parsed.reason.trim() : decision,
			};
		}
	} catch {
		// fall through to fail-open default
	}

	return { decision: "allow", reason: "unparseable reviewer response" };
}


function getCachedDecision(key: string): DecisionResult | undefined {
	const entry = decisionCache.get(key);
	if (entry === undefined) return;
	if (entry.expiresAt > Date.now()) return entry;

	decisionCache.delete(key);
}

function cacheDecision(key: string, result: DecisionResult): void {
	decisionCache.set(key, { ...result, expiresAt: Date.now() + CACHE_TTL_MS });
	if (decisionCache.size <= MAX_CACHE_SIZE) return;

	const oldestKey = decisionCache.keys().next().value;
	if (oldestKey !== undefined) decisionCache.delete(oldestKey);
}

async function reviewToolCall(event: { toolName?: string; input?: unknown }, signal: AbortSignal) {
	const baseUrl = process.env.LLM_PERMISSION_CHECKER_BASE_URL ?? process.env.LITELLM_BASE_URL;
	const apiKey = process.env.LLM_PERMISSION_CHECKER_API_KEY ?? process.env.LITELLM_API_KEY;
	if (!baseUrl || !apiKey) return { decision: "allow" as const, reason: "reviewer not configured" };

	const response = await fetch(`${baseUrl.replace(/\/+$/, "")}/v1/chat/completions`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${apiKey}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify({
			model: process.env.LLM_PERMISSION_CHECKER_MODEL ?? DEFAULT_MODEL,
			temperature: 0,
			response_format: { type: "json_object" },
			messages: [
				{
					role: "system",
					content:
						'You are a permission checker for an AI coding agent operating on a local development machine. Decide if the requested tool call is safe. Return only JSON: {"decision":"allow|ask|deny","reason":"short reason"}. Use deny for clearly dangerous, destructive, exfiltrating, credential, privilege, or host-risky actions. Use allow for ordinary local development actions. Use ask when human intent is required but the call is not clearly malicious.',
				},
				{
					role: "user",
					content: JSON.stringify({ operation: renderOperation(event.toolName, event.input) }),
				},
			],
		}),
		signal,
	});

	if (!response.ok) return { decision: "allow" as const, reason: `reviewer HTTP ${response.status}` };
	const payload = (await response.json()) as { choices?: Array<{ message?: { content?: unknown } }> };
	const content = payload.choices?.[0]?.message?.content;
	return parseDecision(typeof content === "string" ? content : "");
}

function errorForDecision(result: DecisionResult): Error | undefined {
	if (result.decision === "deny") return new Error(`LLM permission checker denied tool call: ${result.reason}`);
	if (result.decision === "ask") return new Error(`LLM permission checker wants human approval: ${result.reason}`);
}

export const LlmPermissionChecker = async () => ({
	"tool.execute.before": async (input: ToolExecuteInput, output: ToolExecuteOutput) => {
		const event = { toolName: input.tool, input: output.args };
		if (isDirectQuestionToUser(event)) {
			throw new Error("LLM permission checker requires human approval for direct questions");
		}

		if (input.tool === undefined) return;

		const hardBlockReason = checkHardBlock(event);
		if (hardBlockReason !== undefined) throw new Error(hardBlockReason);

		if (LOW_RISK_TOOLS[input.tool] === true) return;
		if (REVIEWED_TOOLS[input.tool] !== true && !input.tool.startsWith("mcp_")) return;

		const key = `${input.tool}:${stableStringify(output.args)}`;
		const cached = getCachedDecision(key);
		if (cached !== undefined) {
			const error = errorForDecision(cached);
			if (error !== undefined) throw error;
			return;
		}

		const controller = new AbortController();
		const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

		try {
			const result = await reviewToolCall(event, controller.signal);
			cacheDecision(key, result);
			const error = errorForDecision(result);
			if (error !== undefined) throw error;
		} catch (error) {
			if (error instanceof Error && error.message.startsWith("LLM permission checker ")) throw error;
			return;
		} finally {
			clearTimeout(timeout);
		}
	},
});
