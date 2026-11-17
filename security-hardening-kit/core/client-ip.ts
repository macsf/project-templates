/**
 * Spoof-safe client IP.
 * The LEFTMOST x-forwarded-for entry is attacker-controlled. Each trusted proxy
 * APPENDS the peer it saw, so count from the right.
 *
 * TRUSTED_PROXY_HOPS: Traefik/Caddy only = 1 (default), Cloudflare + Traefik = 2,
 * Vercel = 1, no proxy = 0 (header ignored).
 */
type HeaderReader = { get(name: string): string | null };

export function clientIp(headers: HeaderReader, hops = Number(process.env.TRUSTED_PROXY_HOPS ?? 1)): string {
  if (hops <= 0) return "unknown";
  const parts = (headers.get("x-forwarded-for") ?? "").split(",").map((s) => s.trim()).filter(Boolean);
  if (parts.length === 0) return "unknown";
  return parts[Math.max(0, parts.length - hops)] ?? "unknown";
}
