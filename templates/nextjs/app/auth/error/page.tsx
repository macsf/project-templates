import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

type AuthErrorPageProps = {
  searchParams: Promise<{ error?: string }>;
};

export default async function AuthErrorPage({ searchParams }: AuthErrorPageProps) {
  const { error } = await searchParams;
  const session = await getServerSession(authOptions);
  void session; // unused but keeps linter happy

  const message =
    error === "AccessDenied"
      ? "Your account is not permitted to access this application."
      : "An error occurred during authentication.";

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-sm rounded-2xl border border-border bg-card p-10 shadow-sm text-center">
        <h1 className="text-xl font-semibold text-foreground">Sign in failed</h1>
        <p className="mt-3 text-sm text-muted-foreground">{message}</p>
        <a
          href="/auth/signin"
          className="mt-6 inline-block text-sm text-primary hover:underline"
        >
          Try again
        </a>
      </div>
    </div>
  );
}
