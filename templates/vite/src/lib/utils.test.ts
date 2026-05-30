import { describe, expect, test } from "vitest";
import { cn } from "./utils";

describe("cn", () => {
  test("merges class names", () => {
    expect(cn("px-4", "py-2")).toBe("px-4 py-2");
  });

  test("resolves conflicting tailwind classes", () => {
    expect(cn("p-4", "p-8")).toBe("p-8");
  });

  test("ignores falsy values", () => {
    expect(cn("base", false && "ignored", undefined, null, "active")).toBe("base active");
  });
});
