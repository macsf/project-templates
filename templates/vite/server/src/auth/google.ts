import { OAuth2Client } from "google-auth-library";
import { env } from "../config/env.js";

let client: OAuth2Client | null = null;

function getClient(): OAuth2Client {
  if (!client) {
    client = new OAuth2Client(env.GOOGLE_CLIENT_ID);
  }
  return client;
}

export type GooglePayload = {
  googleId: string;
  email: string;
  name: string | null;
  picture: string | null;
};

export async function verifyGoogleIdToken(credential: string): Promise<GooglePayload> {
  if (!env.GOOGLE_CLIENT_ID) {
    throw new Error("GOOGLE_CLIENT_ID is not configured");
  }

  const ticket = await getClient().verifyIdToken({
    idToken: credential,
    audience: env.GOOGLE_CLIENT_ID,
  });

  const payload = ticket.getPayload();
  if (!payload?.sub) throw new Error("Invalid Google token payload");

  return {
    googleId: payload.sub,
    email: payload.email ?? "",
    name: payload.name ?? null,
    picture: payload.picture ?? null,
  };
}
