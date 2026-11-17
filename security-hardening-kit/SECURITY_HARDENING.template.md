# Security hardening (public deploy)

Living notes for <Dokploy/Coolify/Vercel> deploys. Append incidents under **Incident log**. Do not rewrite history.

## Posture summary

| Threat | Current posture | Further hardening |
| --- | --- | --- |
| Secret/file path probes | Guard returns JSON 404 before SSR/auth | Proxy WAF or fail2ban |
| Brute API / auth | In-memory IP limits (<N>/min API, <N>/min auth), IP from `TRUSTED_PROXY_HOPS=<n>` | Proxy rate limit, Redis if multi-replica |
| Session theft | HttpOnly cookie, `Secure`, unique secret per env | Rotate on incident |
| CSRF | SameSite + exact origin, no wildcard CORS | - |
| XSS | React defaults, no `dangerouslySetInnerHTML` | Tighten CSP `script-src` |
| Clickjacking / MIME | `X-Frame-Options`, CSP `frame-ancestors`, `nosniff` | - |
| Auth bypass flags in prod | `<DISABLE_AUTH / DEV_LOGIN>` must be false | Audit platform env each release |
| Supply chain | Lockfile + `pnpm audit --prod` + Dependabot | - |

## App controls

- Probe blocking: `<path>/probe-paths.ts`, enforced in `<entry file>`
- TRACE/TRACK: 405 in `<entry file>`
- Rate limit: `<path>/rate-limit.ts`, client IP via `<path>/client-ip.ts`
- Headers: `<file>`

## Operational checklist

1. Expect scanner 404 noise. Alert on auth failures, DB errors, unexpected 5xx, not probe 404s.
2. Confirm `TRUSTED_PROXY_HOPS` matches the real proxy chain after any infra change.
3. No secrets in client-exposed env vars.
4. Prefer volume/DB backups over anything served by the app.

## Incident log

- **<date>:** Ported hardening kit baseline.
