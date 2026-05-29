import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { SignInButton } from "@/components/auth/SignInButton";

export default async function Home() {
  const session = await getServerSession(authOptions);

  return (
    <main className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="text-center space-y-6">
        <h1 className="text-4xl font-bold tracking-tight text-foreground">{{PROJECT_TITLE}}</h1>
        <p className="text-muted-foreground text-sm max-w-sm mx-auto">
          {session ? `Welcome, ${session.user?.name ?? session.user?.email}` : "Sign in to continue"}
        </p>
        {!session && (
          <div className="flex justify-center">
            <SignInButton />
          </div>
        )}
      </div>
    </main>
  );
}
