type PermissionDecision = "allow" | "ask" | "deny";

interface ToolExecuteInput {
	tool?: string;
}

interface ToolExecuteOutput {
	args?: unknown;
}

const REVIEWED_TOOLS: Record<string, true> = {
	bash: true,
	edit: true,
	lsp: true,
	task: true,
	write: true,
};

const DEFAULT_MODEL = "claude-haiku-4-5";
const TIMEOUT_MS = 10_000;
const DIRECT_QUESTION_PATTERN = /ask[_-]?user|AskUserQuestion/i;

function isDirectQuestionToUser(event: { toolName?: string; input?: unknown }): boolean {
	if (event.toolName !== undefined && DIRECT_QUESTION_PATTERN.test(event.toolName)) return true;

	try {
		return DIRECT_QUESTION_PATTERN.test(JSON.stringify(event.input));
	} catch {
		return false;
	}
}

function parseDecision(content: string): {
	decision: PermissionDecision;
	reason: string;
} {
	try {
		const parsed = JSON.parse(content) as {
			decision?: unknown;
			reason?: unknown;
		};
		const decision = parsed.decision;
		if (decision === "allow" || decision === "ask" || decision === "deny") {
			return {
				decision,
				reason:
					typeof parsed.reason === "string" && parsed.reason.trim()
						? parsed.reason.trim()
						: decision,
			};
		}
	} catch {
		// fall through to fail-open default
	}

	return { decision: "allow", reason: "unparseable reviewer response" };
}

function shouldReview(toolName: string | undefined): toolName is string {
	return (
		toolName !== undefined &&
		(REVIEWED_TOOLS[toolName] === true || toolName.startsWith("mcp__"))
	);
}

async function reviewToolCall(
	event: { toolName?: string; input?: unknown },
	signal: AbortSignal,
) {
	const baseUrl =
		process.env.LLM_PERMISSION_CHECKER_BASE_URL ?? process.env.LITELLM_BASE_URL;
	const apiKey =
		process.env.LLM_PERMISSION_CHECKER_API_KEY ?? process.env.LITELLM_API_KEY;
	if (!baseUrl || !apiKey) {
		return { decision: "allow" as const, reason: "reviewer not configured" };
	}

	const response = await fetch(
		`${baseUrl.replace(/\/+$/, "")}/v1/chat/completions`,
		{
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
							'You are a permission checker for an AI coding agent. Decide if the requested tool call is safe. Return only JSON: {"decision":"allow|ask|deny","reason":"short reason"}. Use deny for destructive, exfiltrating, credential, privilege, or host-risky actions. Use allow for ordinary local development actions. Use ask when human intent is required but the call is not clearly malicious.',
					},
					{
						role: "user",
						content: JSON.stringify(event),
					},
				],
			}),
			signal,
		},
	);

	if (!response.ok) {
		return { decision: "allow" as const, reason: `reviewer HTTP ${response.status}` };
	}
	const payload = (await response.json()) as {
		choices?: Array<{ message?: { content?: unknown } }>;
	};
	const content = payload.choices?.[0]?.message?.content;
	return parseDecision(typeof content === "string" ? content : "");
}

export const LlmPermissionChecker = async () => ({
	"tool.execute.before": async (
		input: ToolExecuteInput,
		output: ToolExecuteOutput,
	) => {
		const event = { toolName: input.tool, input: output.args };
		if (isDirectQuestionToUser(event)) {
			throw new Error(
				"LLM permission checker requires human approval for direct questions",
			);
		}
		if (!shouldReview(input.tool)) return;

		const controller = new AbortController();
		const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

		try {
			const result = await reviewToolCall(event, controller.signal);
			if (result.decision === "deny") {
				throw new Error(
					`LLM permission checker denied tool call: ${result.reason}`,
				);
			}
			if (result.decision === "ask") {
				throw new Error(
					`LLM permission checker wants human approval: ${result.reason}`,
				);
			}
		} catch (error) {
			if (error instanceof Error && error.message.startsWith("LLM permission checker ")) {
				throw error;
			}
			return;
		} finally {
			clearTimeout(timeout);
		}
	},
});
