import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, test } from "vitest";

const script = path.join(path.dirname(fileURLToPath(import.meta.url)), "env-merge.mjs");

describe("env-merge", () => {
  test("writes vars then secrets into the destination", () => {
    const dir = mkdtempSync(path.join(tmpdir(), "env-merge-"));
    writeFileSync(path.join(dir, ".env.vars"), "FRONTEND_URL=http://localhost:5173\n");
    writeFileSync(path.join(dir, ".env.secrets"), "SESSION_SECRET=s\n");
    execFileSync(process.execPath, [script, ".env"], { cwd: dir });
    expect(readFileSync(path.join(dir, ".env"), "utf8")).toBe(
      "FRONTEND_URL=http://localhost:5173\n\nSESSION_SECRET=s\n",
    );
  });
});
