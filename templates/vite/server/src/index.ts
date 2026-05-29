import "dotenv/config";
import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import { env } from "./config/env.js";
import { prisma } from "./lib/prisma.js";
import { healthRouter } from "./routes/health.js";
import { authRouter } from "./routes/auth.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();

app.use(
  cors({
    origin: env.FRONTEND_URL,
    credentials: true,
  }),
);
app.use(express.json({ limit: "2mb" }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/health", healthRouter);
app.use("/api/auth", authRouter);

// Serve frontend in production
if (env.NODE_ENV === "production") {
  const distPath = path.join(__dirname, "../../../dist");
  app.use(express.static(distPath));
  app.get("*", (_req, res) => {
    res.sendFile(path.join(distPath, "index.html"));
  });
}

async function start() {
  if (env.DEV_BYPASS_AUTH) {
    console.warn(
      "[warn] DEV_BYPASS_AUTH is enabled — all requests are authenticated as the dev user",
    );
  }

  try {
    await prisma.$connect();
    app.listen(env.PORT, () => {
      console.log(`Server listening on http://localhost:${env.PORT}`);
    });
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

start();
