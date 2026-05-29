import { getServerSession } from "next-auth";
import { redirect } from "next/navigation";
import { authOptions } from "@/lib/auth";
import { SignInButton } from "@/components/auth/SignInButton";

export default async function SignInPage() {
  const session = await getServerSession(authOptions);
  if (session) redirect("/");

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-sm rounded-2xl border border-border bg-card p-10 shadow-sm">
        <h1 className="text-2xl font-bold tracking-tight text-foreground text-center">
          {{PROJECT_TITLE}}
        </h1>
        <p className="mt-2 text-sm text-muted-foreground text-center">Sign in to continue</p>
        <div className="mt-8 flex justify-center">
          <SignInButton />
        </div>
      </div>
    </div>
  );
}
