/** Baseline headers. Tune CSP per app; keep COOP popup-friendly for Google OAuth. */
export function securityHeaders(opts: { hsts?: boolean; frame?: "DENY" | "SAMEORIGIN" } = {}): Record<string, string> {
  const frame = opts.frame ?? "DENY";
  return {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": frame,
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=()",
    "Cross-Origin-Opener-Policy": "same-origin-allow-popups",
    "X-Permitted-Cross-Domain-Policies": "none",
    "Content-Security-Policy": `frame-ancestors ${frame === "DENY" ? "'none'" : "'self'"}; base-uri 'self'; form-action 'self'; object-src 'none'`,
    ...(opts.hsts === false ? {} : { "Strict-Transport-Security": "max-age=31536000; includeSubDomains" }),
  };
}
