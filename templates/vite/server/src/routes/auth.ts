import { Router, type Request, type Response } from "express";
import cookieParser from "cookie-parser";
import { env } from "../config/env.js";
import { prisma } from "../lib/prisma.js";
import { verifyGoogleIdToken } from "../auth/google.js";
import { createSession, deleteSession, loadSession } from "../auth/session.js";
import { requireAuth } from "../middleware/require-auth.js";

export const authRouter = Router();

authRouter.use(cookieParser());
authRouter.use(loadSession);

// POST /api/auth/google — exchange Google credential for a session
authRouter.post("/google", async (req: Request, res: Response) => {
  const { credential } = req.body as { credential?: string };

  if (!credential) {
    res.status(400).json({ error: "credential is required" });
    return;
  }

  // Dev bypass shortcut
  if (credential === "__dev__" && env.DEV_BYPASS_AUTH) {
    let user = await prisma.user.findFirst({
      where: { email: env.DEV_USER_EMAIL ?? "dev@local.test" },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email: env.DEV_USER_EMAIL ?? "dev@local.test",
          name: env.DEV_USER_NAME ?? "Dev User",
        },
      });
    }

    await createSession(res, user.id);
    res.json({ id: user.id, email: user.email, name: user.name, picture: user.picture });
    return;
  }

  try {
    const payload = await verifyGoogleIdToken(credential);

    // Check allowed emails if configured
    if (env.ALLOWED_EMAILS) {
      const allowed = env.ALLOWED_EMAILS.split(",").map((e) => e.trim().toLowerCase());
      if (!allowed.includes(payload.email.toLowerCase())) {
        res.status(403).json({ error: "Email not allowed" });
        return;
      }
    }

    // Upsert user
    const user = await prisma.user.upsert({
      where: { googleId: payload.googleId },
      update: { email: payload.email, name: payload.name, picture: payload.picture },
      create: {
        googleId: payload.googleId,
        email: payload.email,
        name: payload.name,
        picture: payload.picture,
      },
    });

    await createSession(res, user.id);
    res.json({ id: user.id, email: user.email, name: user.name, picture: user.picture });
  } catch (err) {
    console.error("[auth/google] error:", err);
    res.status(401).json({ error: "Authentication failed" });
  }
});

// GET /api/auth/me — return current user
authRouter.get("/me", requireAuth, (req: Request, res: Response) => {
  res.json(req.user);
});

// POST /api/auth/signout — clear session
authRouter.post("/signout", async (req: Request, res: Response) => {
  await deleteSession(req, res);
  res.json({ ok: true });
});
