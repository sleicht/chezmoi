import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type PermissionDecision = "allow" | "ask" | "deny";

interface DecisionResult {
	decision: PermissionDecision;
	reason: string;
}

interface CacheEntry extends DecisionResult {
	expiresAt: number;
}

const REVIEWED_TOOLS: Record<string, true> = {
	ast_edit: true,
	bash: true,
	browser: true,
	debug: true,
	edit: true,
	eval: true,
	lsp: true,
	resolve: true,
	task: true,
	write: true,
};

const LOW_RISK_TOOLS: Record<string, true> = {
	find: true,
	read: true,
	search: true,
};

const HARD_BLOCK_PATTERNS: Record<string, Array<{ pattern: RegExp; reason: string }>> = {
	bash: [
		{ pattern: /\bsudo\b/i, reason: "sudo commands require explicit approval" },
		{ pattern: /\brm\s+(-rf?|--recursive)\s+(\/|~)/i, reason: "Destructive removal of root or home directory" },
		{ pattern: /\bmkfs\b/i, reason: "Disk formatting is not allowed" },
		{ pattern: /\bdd\s+.*of=\/dev\//i, reason: "Direct disk writes are not allowed" },
		{ pattern: /\b(chmod|chown)\b.*777/i, reason: "Overly permissive file permissions" },
		{ pattern: /\bchown\b.*\/(etc|usr|var|sys|proc)/i, reason: "Cannot change ownership of system directories" },
		{ pattern: /\b(curl|wget|ssh|scp)\b/i, reason: "External network access requires approval" },
		{ pattern: /\bkill\s+-9\b.*(init|systemd|1\b)/i, reason: "Cannot kill system processes" },
	],
	edit: [{ pattern: /(\/etc\/|\/usr\/|\/var\/|\/sys\/|\/proc\/)/i, reason: "Cannot edit system configuration files" }],
	write: [{ pattern: /(\/etc\/|\/usr\/|\/var\/|\/sys\/|\/proc\/)/i, reason: "Cannot write to system directories" }],
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

function shouldReviewTool(toolName: string): boolean {
	return REVIEWED_TOOLS[toolName] === true || toolName.startsWith("mcp__");
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
	if (toolName === "bash" && isRecord(input) && typeof input.command === "string") return `bash: ${input.command}`;
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

function cacheKey(event: { toolName?: string; input?: unknown }): string {
	return `${event.toolName ?? ""}:${stableStringify(event.input)}`;
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

async function reviewToolCall(event: { toolName?: string; input?: unknown }, context: { cwd?: string }, signal: AbortSignal) {
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
					content: JSON.stringify({ cwd: context.cwd, operation: renderOperation(event.toolName, event.input) }),
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

function blockForDecision(result: DecisionResult): { block: true; reason: string } | undefined {
	if (result.decision === "deny") return { block: true, reason: `LLM permission checker denied tool call: ${result.reason}` };
	if (result.decision === "ask") return { block: true, reason: `LLM permission checker wants human approval: ${result.reason}` };
}

export default function llmPermissionChecker(pi: ExtensionAPI): void {
	pi.on("tool_call", async (event, context) => {
		if (isDirectQuestionToUser(event)) {
			return { block: true, reason: "LLM permission checker requires human approval for direct questions" };
		}

		if (event.toolName === undefined) return;

		const hardBlockReason = checkHardBlock(event);
		if (hardBlockReason !== undefined) return { block: true, reason: hardBlockReason };

		if (LOW_RISK_TOOLS[event.toolName] === true) return;
		if (!shouldReviewTool(event.toolName)) return;

		const key = cacheKey(event);
		const cached = getCachedDecision(key);
		if (cached !== undefined) return blockForDecision(cached);

		const controller = new AbortController();
		const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

		try {
			const result = await reviewToolCall(event, context, controller.signal);
			cacheDecision(key, result);
			return blockForDecision(result);
		} catch {
			return;
		} finally {
			clearTimeout(timeout);
		}
	});
}
