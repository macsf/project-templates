# Security Hardening Kit (public web app baseline)

Framework-agnostic baseline for apps exposed to the internet behind a reverse proxy (Traefik, Caddy, Nginx, Vercel, Cloudflare). Code in `core/` has no dependencies and runs on any JS runtime with Web `Headers`.

## What it does

| Control | Behavior |
| --- | --- |
| Probe 404 | `.env`, `.git`, `*.php`, backups, hidden segments, traversal return JSON 404 before render or auth redirect |
| Method reject | `TRACE`/`TRACK` return 405 |
| IP rate limit | API about 100-120/min, auth POST 20-30/min, in-memory, 429 + `Retry-After` |
| Headers | nosniff, frame deny, referrer, permissions, COOP popup-friendly, CSP (non-script directives), HSTS |
| robots.txt | `Disallow: /` (soft signal only) |

Goal: stop scanners getting 200/302 (which looks "alive") and blunt anonymous hammering. Not a WAF.

## Pitfalls this kit fixes (check any existing app for these)

| Sev | Pitfall | Fix |
| --- | --- | --- |
| High | Client IP read from the leftmost `x-forwarded-for` (client-controlled). Rotating the header gives a new bucket per request, so limits are bypassed. `x-real-ip` fallback has the same trust problem | `core/client-ip.ts`: count from the right by `TRUSTED_PROXY_HOPS`. Fastify `trustProxy: true` and Express `trust proxy: true` have the same flaw |
| Med | Limiter map pruned only past a threshold or only for expired keys, so spoofed IPs grow memory | `core/rate-limit.ts` hard-caps keys and evicts oldest |
| Med | No CSP or HSTS | `core/security-headers.ts`, or set at the proxy |
| Med | Auth middleware skips some API routes (API-key routes) | Every skipped route must enforce session or key in its handler. Add a test that calls each unauthenticated and expects 401 |
| Med | SPA fallback or auth redirect answers probe paths with 200/302 | Probe gate runs before fallback and auth |
| Low | Hidden-segment rule blocks `/.well-known/*` (ACME, domain verification) | Pass `allow: ["/.well-known/"]` if needed |
| Low | Missing IP puts everyone in one `unknown` bucket | Fine behind a proxy; log if it appears |
| Info | Per-process limiter is best-effort across replicas or serverless | Redis/Upstash or proxy-level limit |

Out of scope: auth logic, database, paid-API spend caps.

## Port checklist

1. Copy `core/*.ts` into the target (for example `lib/security/`). No dependencies.
2. Set `TRUSTED_PROXY_HOPS` in platform env, not the repo: one proxy (Traefik, Caddy, Nginx, Vercel) = 1, CDN plus proxy = 2, no proxy = 0 (header ignored).
3. Wire one gate at the earliest request point (adapters below). Order: method reject, probe 404, rate limit, then app and auth.
4. Real static files must be served before the probe gate or excluded from the matcher. Set `blockAssetExt: true` only where misses would fall through to `index.html`.
5. Keep `public/robots.txt` as `Disallow: /` for internal tools.
6. Copy `SECURITY_HARDENING.template.md` to `docs/`, fill the blanks, append incidents only.
7. Run `core/hardening.test.ts`, then lint, `audit --prod` and the production build.
8. Append `TRUSTED_PROXY_HOPS` to the example env template (never edit real env files).
9. Production flags that must be false: auth-disable and dev-login switches. No secrets in client-exposed vars (`VITE_*`, `NEXT_PUBLIC_*`).
10. Smoke test on staging:
    ```sh
    curl -si https://HOST/.env | head -1               # 404
    curl -si -X TRACE https://HOST/ | head -1           # 405
    curl -si https://HOST/ | grep -i "x-frame\|strict-transport"
    for i in $(seq 1 130); do curl -so /dev/null -w "%{http_code}\n" -H "X-Forwarded-For: 1.1.1.$i" https://HOST/api/x; done | sort | uniq -c   # must still reach 429
    ```

## Adapters

Imports below assume `core/` copied to `lib/security/`. Wire the same four steps everywhere: method, probe, rate limit, headers.

### Next.js (middleware, or `proxy.ts` in v16+)
```ts
import { isProbePath } from "@/lib/security/probe-paths";
import { clientIp } from "@/lib/security/client-ip";
import { hit } from "@/lib/security/rate-limit";

const json = (status: number, error: string, retry?: number) =>
  new NextResponse(JSON.stringify({ error }), {
    status,
    headers: { "content-type": "application/json", ...(retry ? { "retry-after": String(retry) } : {}) },
  });

if (["TRACE", "TRACK"].includes(req.method)) return json(405, "Method not allowed");
if (isProbePath(req.nextUrl.pathname, { blockAssetExt: true, allow: ["/robots.txt"] })) return json(404, "Not found");
if (path.startsWith("/api")) {
  const isAuth = path.startsWith("/api/auth");
  const r = hit(`${isAuth ? "auth" : "api"}:${clientIp(req.headers)}`, isAuth ? 20 : 100);
  if (!r.allowed) return json(429, "Too many requests", r.retryAfterSec);
}
```
- Compose before the auth wrapper (NextAuth/Auth.js `withAuth`) so probes never reach the sign-in redirect.
- Matcher: exclude `_next/static`, `_next/image` and real public assets, but keep extension paths like `/.env` and `*.php` inside it.
- Headers: use `securityHeaders({ frame: "SAMEORIGIN" })` in `next.config` `headers()`.
- Rate limit is per instance on Vercel/serverless: best-effort. Use Upstash for strict limits.

### Fastify (API plus Vite SPA)
```ts
const app = Fastify({
  // Number form is untyped in some versions; the function form is equivalent.
  trustProxy: (_addr: string, hop: number) => hop < Number(process.env.TRUSTED_PROXY_HOPS ?? 1),
});
app.addHook("onRequest", async (req, reply) => {
  for (const [k, v] of Object.entries(securityHeaders())) reply.header(k, v);
  if (req.method === "TRACE" || req.method === "TRACK") return reply.code(405).send({ error: "Method not allowed" });
});
app.setNotFoundHandler((req, reply) => {
  if (req.method !== "GET" || isProbePath(req.url, { blockAssetExt: true }) || req.url.startsWith("/api"))
    return reply.code(404).send({ error: "Not found" });
  return reply.sendFile("index.html"); // SPA fallback only for navigable routes
});
```
- Keep `@fastify/rate-limit` with `keyGenerator: (r) => r.ip` (correct once `trustProxy` is set), a stricter per-route limit on auth, and `allowList` for non-API paths.
- Register `@fastify/static` first so real assets are served before the not-found handler.
- Health check route: exempt from rate limit.

### Express
```ts
app.set("trust proxy", Number(process.env.TRUSTED_PROXY_HOPS ?? 1)); // never `true`
app.use((req, res, next) => {
  Object.entries(securityHeaders()).forEach(([k, v]) => res.setHeader(k, v));
  if (req.method === "TRACE" || req.method === "TRACK") return res.status(405).json({ error: "Method not allowed" });
  if (isProbePath(req.originalUrl)) return res.status(404).json({ error: "Not found" });
  next();
});
```
Put this before `express.static` only if static assets pass the probe check; otherwise mount static first. `express-rate-limit` with the `trust proxy` number above is an alternative to `hit()`.

### TanStack Start, Nitro, h3, Hono (Fetch-API servers)
One gate before the SSR handler, then wrap the response:
```ts
export function guardRequest(request: Request): Response | null {
  if (["TRACE", "TRACK"].includes(request.method)) return json(405, "Method not allowed");
  const path = pathnameFromUrl(request.url);
  if (isProbePath(path)) return json(404, "Not found");
  if (path.startsWith("/api/") || path.startsWith("/_serverFn/")) {
    const r = hit(`api:${clientIp(request.headers)}`, 120);
    if (!r.allowed) return json(429, "Too many requests", r.retryAfterSec);
  }
  return null;
}
// entry: const blocked = guardRequest(req); if (blocked) return blocked; return withHeaders(await handler(req));
```
Rate-limit server-function routes too: they carry paid or heavy work and are not under `/api`.

### Vite SPA on a static host (Nginx, Caddy, S3/CDN)
No app server to gate, so do it at the host:
```nginx
location ~ /\.(?!well-known) { return 404; }
location ~* \.(env|php|sql|bak|zip|tar|gz|pem|key|yml|yaml|log)$ { return 404; }
if ($request_method ~ ^(TRACE|TRACK)$) { return 405; }
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options DENY always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
try_files $uri /index.html;   # only after the blocks above
```
Rate limiting: `limit_req_zone` in Nginx, rate-limit middleware in Traefik, `rate_limit` in Caddy.

### Laravel, Django, Rails and other non-JS stacks
Port the logic, not the code: same four steps in the earliest middleware, proxy trust set to a hop count (`TrustProxies`, `SECURE_PROXY_SSL_HEADER`, `config.action_dispatch.trusted_proxies`), and a rate limiter keyed by the proxy-appended IP.

## Proxy layer (no CDN/WAF)

- Rate-limit middleware on the service in Traefik or Caddy. Never block OAuth callbacks (for example `/api/auth/callback/google`).
- fail2ban on the VPS watching the proxy access log for repeated probe 404s and 429s. Enable only after confirming the log format.
- No User-Agent blocklists (spoofable, false positives).

## Decisions to confirm per project

- Per-IP numbers: dashboards firing many parallel calls need the higher API limit.
- CSP `script-src`: left open for tag managers and Google Identity. Tighten only if those are absent.
- Replica count: more than one needs a shared limiter store.
- Hop count after any infra change (adding or removing a CDN or proxy).
