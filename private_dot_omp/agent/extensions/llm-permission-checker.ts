type PermissionDecision = "allow" | "ask" | "deny";

interface ToolCallEvent {
  toolName?: string;
  input?: unknown;
}

interface ExtensionContext {
  cwd?: string;
}

interface ExtensionAPI {
  on(
    event: "tool_call",
    handler: (
      event: ToolCallEvent,
      context: ExtensionContext,
    ) => Promise<{ block: true; reason: string } | undefined> | { block: true; reason: string } | undefined,
  ): void;
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

const DEFAULT_MODEL = "claude-haiku-4-5";
const TIMEOUT_MS = 10_000;

function parseDecision(content: string): { decision: PermissionDecision; reason: string } {
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

async function reviewToolCall(event: ToolCallEvent, context: ExtensionContext, signal: AbortSignal) {
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
            "You are a permission checker for an AI coding agent. Decide if the requested tool call is safe. Return only JSON: {\"decision\":\"allow|ask|deny\",\"reason\":\"short reason\"}. Use deny for destructive, exfiltrating, credential, privilege, or host-risky actions. Use allow for ordinary local development actions. Use ask when human intent is required but the call is not clearly malicious.",
        },
        {
          role: "user",
          content: JSON.stringify({ cwd: context.cwd, toolName: event.toolName, input: event.input }),
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

export default function llmPermissionChecker(pi: ExtensionAPI): void {
  pi.on("tool_call", async (event, context) => {
    if (event.toolName === undefined || (REVIEWED_TOOLS[event.toolName] !== true && !event.toolName.startsWith("mcp__"))) return;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

    try {
      const result = await reviewToolCall(event, context, controller.signal);
      if (result.decision === "deny") {
        return { block: true, reason: `LLM permission checker denied tool call: ${result.reason}` };
      }
      if (result.decision === "ask") {
        return { block: true, reason: `LLM permission checker wants human approval: ${result.reason}` };
      }
    } catch {
      return;
    } finally {
      clearTimeout(timeout);
    }
  });
}
