import { useEffect, useState } from "react";
import { ThemeProvider } from "@/lib/theme";
import { Toaster } from "@/components/ui/sonner";
import { Loader2 } from "lucide-react";

// ── Types ─────────────────────────────────────────────────────────────────────

type AuthUser = {
  id: string;
  email: string;
  name: string | null;
  picture: string | null;
};

type RoutePath = "/" | "/login" | "/app";

// ── Router helpers ─────────────────────────────────────────────────────────────

function navigate(to: RoutePath) {
  window.history.pushState({}, "", to);
  window.dispatchEvent(new PopStateEvent("popstate"));
}

function usePathname() {
  const [pathname, setPathname] = useState(window.location.pathname);

  useEffect(() => {
    const onPopState = () => setPathname(window.location.pathname);
    window.addEventListener("popstate", onPopState);
    return () => window.removeEventListener("popstate", onPopState);
  }, []);

  return pathname;
}

// ── Auth helpers ───────────────────────────────────────────────────────────────

async function fetchCurrentUser(): Promise<AuthUser | null> {
  try {
    const res = await fetch("/api/auth/me", { credentials: "include" });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

async function signOut(): Promise<void> {
  await fetch("/api/auth/signout", { method: "POST", credentials: "include" });
}

// ── Root app ───────────────────────────────────────────────────────────────────

export function App() {
  const pathname = usePathname();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoadingAuth, setIsLoadingAuth] = useState(true);

  useEffect(() => {
    fetchCurrentUser().then((u) => {
      setUser(u);
      setIsLoadingAuth(false);
    });
  }, []);

  useEffect(() => {
    if (isLoadingAuth) return;
    if (user && (pathname === "/" || pathname === "/login")) {
      navigate("/app");
    } else if (!user && pathname !== "/" && pathname !== "/login") {
      navigate("/login");
    }
  }, [isLoadingAuth, pathname, user]);

  const handleSignOut = async () => {
    await signOut();
    setUser(null);
    navigate("/login");
  };

  if (isLoadingAuth) {
    return (
      <ThemeProvider>
        <LoadingScreen label="Loading..." />
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider>
      <AppRouter
        pathname={pathname}
        user={user}
        onSignIn={setUser}
        onSignOut={handleSignOut}
      />
      <Toaster />
    </ThemeProvider>
  );
}

function AppRouter({
  pathname,
  user,
  onSignIn,
  onSignOut,
}: {
  pathname: string;
  user: AuthUser | null;
  onSignIn: (user: AuthUser) => void;
  onSignOut: () => void;
}) {
  if (pathname === "/" || pathname === "/login") {
    if (user) return <LoadingScreen label="Redirecting..." />;
    return <LoginPage onSignIn={onSignIn} />;
  }

  if (pathname === "/app") {
    if (!user) return <LoadingScreen label="Redirecting..." />;
    return <AppShell user={user} onSignOut={onSignOut} />;
  }

  return <NotFoundPage />;
}

// ── Pages ──────────────────────────────────────────────────────────────────────

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined;

function LoginPage({ onSignIn }: { onSignIn: (user: AuthUser) => void }) {
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleDevSignIn = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/auth/google", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ credential: "__dev__" }),
      });
      if (!res.ok) throw new Error("Sign in failed");
      const user: AuthUser = await res.json();
      onSignIn(user);
      navigate("/app");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign in failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-sm rounded-2xl border border-border bg-card p-10 shadow-sm">
        <h1 className="text-2xl font-bold tracking-tight text-foreground text-center">
          {{PROJECT_TITLE}}
        </h1>
        <p className="mt-2 text-sm text-muted-foreground text-center">Sign in to continue</p>

        <div className="mt-8 space-y-3">
          {error && (
            <div className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-xs text-destructive">
              {error}
            </div>
          )}

          {!GOOGLE_CLIENT_ID && (
            <button
              onClick={handleDevSignIn}
              disabled={loading}
              className="w-full inline-flex items-center justify-center gap-2 h-10 rounded-lg border border-border bg-secondary text-sm font-medium hover:bg-secondary/80 transition-colors disabled:opacity-70"
            >
              {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Continue (dev)
            </button>
          )}

          {GOOGLE_CLIENT_ID && (
            <div id="google-signin-button" className="flex justify-center" />
          )}
        </div>
      </div>
    </div>
  );
}

function AppShell({ user, onSignOut }: { user: AuthUser; onSignOut: () => void }) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="border-b border-border bg-card px-6 py-3 flex items-center justify-between">
        <h1 className="text-lg font-semibold">{{PROJECT_TITLE}}</h1>
        <div className="flex items-center gap-3">
          <span className="text-sm text-muted-foreground">{user.email}</span>
          <button
            onClick={onSignOut}
            className="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Sign out
          </button>
        </div>
      </header>

      <main className="container mx-auto px-6 py-10">
        <p className="text-muted-foreground text-sm">
          Welcome, {user.name ?? user.email}. Start building here.
        </p>
      </main>
    </div>
  );
}

function LoadingScreen({ label }: { label: string }) {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center">
      <div className="inline-flex items-center gap-2 text-sm text-muted-foreground">
        <Loader2 className="h-4 w-4 animate-spin" />
        {label}
      </div>
    </div>
  );
}

function NotFoundPage() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-4">
      <div className="text-center">
        <h1 className="text-7xl font-bold text-foreground">404</h1>
        <p className="mt-4 text-sm text-muted-foreground">Page not found.</p>
        <button
          onClick={() => navigate("/login")}
          className="mt-6 inline-flex items-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
        >
          Go home
        </button>
      </div>
    </div>
  );
}
