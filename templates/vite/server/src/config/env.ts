import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(3001),
  FRONTEND_URL: z.string().url(),
  DATABASE_URL: z.string().min(1),
  SHADOW_DATABASE_URL: z.string().optional(),
  SESSION_SECRET: z.string().min(32),
  GOOGLE_CLIENT_ID: z.string().optional(),
  GOOGLE_CLIENT_SECRET: z.string().optional(),
  ALLOWED_EMAILS: z.string().optional(),
  DEV_BYPASS_AUTH: z
    .string()
    .transform((v) => v === "true")
    .default("false"),
  DEV_USER_EMAIL: z.string().optional(),
  DEV_USER_NAME: z.string().optional(),
});

const result = envSchema.safeParse(process.env);

if (!result.success) {
  console.error("Invalid environment variables:");
  for (const [key, issues] of Object.entries(result.error.flatten().fieldErrors)) {
    console.error(`  ${key}: ${(issues as string[]).join(", ")}`);
  }
  process.exit(1);
}

export const env = result.data;
