import { describe, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import miseJustEnforcer from "./mise-just-enforcer";

describe("miseJustEnforcer", () => {
  test("registers an OMP tool_call handler", () => {
    const registrations: string[] = [];
    const pi = {
      on(eventName: string) {
        registrations.push(eventName);
      },
    };

    const result = miseJustEnforcer(pi as never);

    expect(result).toBeUndefined();
    expect(registrations).toEqual(["tool_call"]);
  });

  test("blocks bash gradlew when mise config exists", async () => {
    const handlers: Array<(event: { toolName?: string; input?: { command?: unknown } }, context: { cwd?: string }) => unknown> = [];
    const pi = {
      on(_eventName: string, handler: (event: { toolName?: string; input?: { command?: unknown } }, context: { cwd?: string }) => unknown) {
        handlers.push(handler);
      },
    };

    const cwd = mkdtempSync(join(tmpdir(), "mise-just-enforcer-"));
    writeFileSync(join(cwd, "mise.toml"), "[tasks.test]\nrun = 'echo test'\n");

    miseJustEnforcer(pi as never);
    const result = await handlers[0]?.({ toolName: "bash", input: { command: "./gradlew test" } }, { cwd });

    expect(result).toEqual({
      block: true,
      reason: expect.stringContaining("Direct gradle/gradlew call blocked"),
    });
  });
});
