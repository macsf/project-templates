/**
 * Fixed-window in-memory limiter. Per process only: fine for one container,
 * best-effort on serverless. Upgrade to Redis/Upstash for multi-replica.
 */
type Bucket = { count: number; resetAt: number };
const buckets = new Map<string, Bucket>();
const MAX_KEYS = 10_000;

export type Limit = { allowed: true } | { allowed: false; retryAfterSec: number };

export function hit(key: string, max: number, windowMs = 60_000, now = Date.now()): Limit {
  const b = buckets.get(key);
  if (!b || b.resetAt <= now) {
    if (buckets.size >= MAX_KEYS) {
      for (const [k, v] of buckets) if (v.resetAt <= now) buckets.delete(k);
      // Still full of live keys: drop oldest so memory stays bounded.
      if (buckets.size >= MAX_KEYS) buckets.delete(buckets.keys().next().value as string);
    }
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return { allowed: true };
  }
  if (b.count >= max) return { allowed: false, retryAfterSec: Math.max(1, Math.ceil((b.resetAt - now) / 1000)) };
  b.count += 1;
  return { allowed: true };
}

export function resetRateLimitForTests(): void {
  buckets.clear();
}
