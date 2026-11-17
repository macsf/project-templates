/** Scanner/leak probe detection. Pure function, no framework imports. */

const BLOCKED_PREFIXES = [
  "/wp-", "/wordpress", "/phpmyadmin", "/adminer", "/cgi-bin", "/actuator",
  "/_vti_", "/vendor/", "/server-status", "/server-info",
];

const BLOCKED_EXT =
  /\.(?:env(?:\..+)?|php\d?|phtml|asp|aspx|jsp|cgi|sql|bak|old|orig|save|swp|zip|tar|tgz|gz|rar|7z|pem|key|p12|pfx|crt|cer|yml|yaml|ini|cfg|conf|config|log|sh|bash|zsh|py|rb|pl|git|svn|htaccess|htpasswd|DS_Store|dump)$/i;

/** Only for apps with no real file routes. Skip for Next.js (public assets) unless matcher excludes them. */
const ASSET_EXT = /\.(?:js|mjs|cjs|css|map|json|xml|wasm|txt)$/i;

const SECRET_NAMES = /(?:^|\/)(?:backup|dump|secrets?|credentials|id_rsa|id_ed25519)(?:[-._]|$)/i;

export type ProbeOptions = {
  /** 404 on asset-like extensions that reach the app (static files must be served before this runs). */
  blockAssetExt?: boolean;
  /** Paths that must stay reachable, e.g. ["/robots.txt", "/.well-known/"]. */
  allow?: string[];
};

export function pathnameFromUrl(url: string): string {
  let p = url;
  try {
    p = /^https?:\/\//i.test(url) ? new URL(url).pathname : (url.split("?")[0] ?? "/");
  } catch {
    p = url.split("?")[0] ?? "/";
  }
  try {
    return decodeURIComponent(p);
  } catch {
    return p;
  }
}

export function isProbePath(urlOrPath: string, opts: ProbeOptions = {}): boolean {
  const path = pathnameFromUrl(urlOrPath);
  const lower = path.toLowerCase();

  if (opts.allow?.some((a) => lower === a || (a.endsWith("/") && lower.startsWith(a)))) return false;
  if (!path.startsWith("/") || path.startsWith("//")) return true;
  if (path.includes("\0") || path.includes("\\")) return true;
  if (path.split("/").some((s) => s.startsWith("."))) return true;
  if (BLOCKED_PREFIXES.some((p) => lower.startsWith(p))) return true;
  if (BLOCKED_EXT.test(path)) return true;
  if (opts.blockAssetExt && ASSET_EXT.test(path)) return true;
  return SECRET_NAMES.test(path);
}
