import type { Request, Response, NextFunction } from "express";
import crypto from "crypto";
import { env } from "../config/env.js";
import { prisma } from "../lib/prisma.js";

const SESSION_COOKIE_NAME = "{{PROJECT_NAME}}_session";
const SESSION_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

// ── HMAC helpers ───────────────────────────────────────────────────────────────

function sign(token: string): string {
  return crypto.createHmac("sha256", env.SESSION_SECRET).update(token).digest("base64url");
}

function createSigned(token: string): string {
  return `${token}.${sign(token)}`;
}

function verify(signed: string): string | null {
  const dotIndex = signed.lastIndexOf(".");
  if (dotIndex === -1) return null;
  const token = signed.slice(0, dotIndex);
  const sig = signed.slice(dotIndex + 1);
  const expected = sign(token);
  if (!crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected))) return null;
  return token;
}

// ── Session token ──────────────────────────────────────────────────────────────

function generateToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

// ── Cookie helpers ─────────────────────────────────────────────────────────────

export function setSessionCookie(res: Response, signedToken: string) {
  res.cookie(SESSION_COOKIE_NAME, signedToken, {
    httpOnly: true,
    secure: env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: SESSION_MAX_AGE_MS,
    path: "/",
  });
}

export function clearSessionCookie(res: Response) {
  res.clearCookie(SESSION_COOKIE_NAME, { path: "/" });
}

// ── Session creation / deletion ────────────────────────────────────────────────

export async function createSession(
  res: Response,
  userId: string,
): Promise<void> {
  const token = generateToken();
  const expiresAt = new Date(Date.now() + SESSION_MAX_AGE_MS);

  await prisma.session.create({
    data: { userId, token, expiresAt },
  });

  setSessionCookie(res, createSigned(token));
}

export async function deleteSession(req: Request, res: Response): Promise<void> {
  const signedToken = req.cookies?.[SESSION_COOKIE_NAME] as string | undefined;
  if (signedToken) {
    const token = verify(signedToken);
    if (token) {
      await prisma.session.deleteMany({ where: { token } }).catch(() => null);
    }
  }
  clearSessionCookie(res);
}

// ── Session validation middleware ──────────────────────────────────────────────

export type SessionUser = {
  id: string;
  email: string;
  name: string | null;
  picture: string | null;
};

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: SessionUser;
    }
  }
}

export async function loadSession(
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> {
  // Dev bypass
  if (env.DEV_BYPASS_AUTH) {
    let devUser = await prisma.user.findFirst({
      where: { email: env.DEV_USER_EMAIL ?? "dev@local.test" },
    });

    if (!devUser) {
      devUser = await prisma.user.create({
        data: {
          email: env.DEV_USER_EMAIL ?? "dev@local.test",
          name: env.DEV_USER_NAME ?? "Dev User",
        },
      });
    }

    req.user = {
      id: devUser.id,
      email: devUser.email,
      name: devUser.name ?? null,
      picture: devUser.picture ?? null,
    };
    return next();
  }

  const signedToken = req.cookies?.[SESSION_COOKIE_NAME] as string | undefined;
  if (!signedToken) return next();

  const token = verify(signedToken);
  if (!token) return next();

  const session = await prisma.session.findUnique({
    where: { token },
    include: { user: true },
  });

  if (!session || session.expiresAt < new Date()) {
    if (session) await prisma.session.delete({ where: { token } }).catch(() => null);
    return next();
  }

  req.user = {
    id: session.user.id,
    email: session.user.email,
    name: session.user.name ?? null,
    picture: session.user.picture ?? null,
  };

  next();
}
