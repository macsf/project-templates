// Run: node --experimental-strip-types --test core/hardening.test.ts  (Node 22+), or tsx --test
import { test } from "node:test";
import assert from "node:assert/strict";
import { isProbePath } from "./probe-paths.ts";
import { clientIp } from "./client-ip.ts";
import { hit, resetRateLimitForTests } from "./rate-limit.ts";

const h = (v: string | null) => ({ get: () => v });

test("blocks .env", () => assert.equal(isProbePath("/.env"), true));
test("blocks nested .env", () => assert.equal(isProbePath("/api/.env"), true));
test("blocks php", () => assert.equal(isProbePath("/wp-admin/setup-config.php"), true));
test("blocks encoded traversal", () => assert.equal(isProbePath("/%2e%2e/etc/passwd"), true));
test("blocks backup name", () => assert.equal(isProbePath("/backup"), true));
test("allows app route", () => assert.equal(isProbePath("/dashboard/seo"), false));
test("allows .well-known when listed", () => assert.equal(isProbePath("/.well-known/x", { allow: ["/.well-known/"] }), false));
test("asset ext only when enabled", () => {
  assert.equal(isProbePath("/missing.js"), false);
  assert.equal(isProbePath("/missing.js", { blockAssetExt: true }), true);
});

test("ip uses rightmost hop, ignores spoofed left", () => assert.equal(clientIp(h("1.2.3.4, 9.9.9.9"), 1), "9.9.9.9"));
test("ip with two hops", () => assert.equal(clientIp(h("1.1.1.1, 9.9.9.9, 10.0.0.1"), 2), "9.9.9.9"));
test("ip ignored when no proxy", () => assert.equal(clientIp(h("1.2.3.4"), 0), "unknown"));

test("limiter blocks after max", () => {
  resetRateLimitForTests();
  hit("k", 2, 60_000, 0);
  hit("k", 2, 60_000, 0);
  assert.equal(hit("k", 2, 60_000, 0).allowed, false);
});
test("limiter resets after window", () => {
  resetRateLimitForTests();
  hit("k", 1, 1000, 0);
  assert.equal(hit("k", 1, 1000, 1001).allowed, true);
});
