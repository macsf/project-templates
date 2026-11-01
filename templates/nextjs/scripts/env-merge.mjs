// Concatenate `.env.vars` + `.env.secrets` into one file Next and Compose can load.
// Default outputs: `.env.local` (Next) and `.env` (Docker Compose interpolation).
import { readFileSync, writeFileSync } from "node:fs";

const sources = [".env.vars", ".env.secrets"];
const dests = process.argv.slice(2);
if (dests.length === 0) dests.push(".env.local", ".env");

function load(path) {
  try {
    return readFileSync(path, "utf8").replace(/\s+$/, "");
  } catch {
    console.error(`missing ${path} (copy from ${path}.example)`);
    process.exit(1);
  }
}

for (const dest of dests) {
  if (dest.endsWith(".example")) {
    console.error(`refusing to write ${dest}`);
    process.exit(1);
  }
}

const body = `${sources.map(load).filter(Boolean).join("\n\n")}\n`;
for (const dest of dests) {
  writeFileSync(dest, body);
  console.log(`wrote ${dest}`);
}
