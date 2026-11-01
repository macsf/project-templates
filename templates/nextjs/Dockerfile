# syntax=docker/dockerfile:1
# Next.js + Prisma. Entrypoint runs `prisma migrate deploy` then `next start`.

ARG NODE_VERSION={{NODE_VERSION}}

FROM node:${NODE_VERSION}-bookworm-slim AS base
ENV PNPM_HOME=/pnpm \
    PATH=/pnpm:$PATH \
    HUSKY=0 \
    CI=true \
    NEXT_TELEMETRY_DISABLED=1
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssl ca-certificates gosu \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable
WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
# Skip lifecycle scripts: postinstall runs `prisma generate`, schema is copied later.
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --ignore-scripts

FROM deps AS build
RUN mkdir -p public
COPY . .
# prisma.config / generate need DB_* even when not connecting. Placeholders only.
ENV DATABASE_URL="file:./dev.db" \
    NEXT_TELEMETRY_DISABLED=1 \
    NODE_ENV=production
RUN pnpm exec prisma generate \
  && pnpm exec next build

# Do not prune: prisma CLI is a devDependency and is required for migrate-on-start.

FROM base AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=8080 \
    HOSTNAME=0.0.0.0 \
    HOST_UID=0 \
    HOST_GID=0 \
    HOME=/home/app

RUN mkdir -p /data /home/app

COPY --from=build /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.ts ./
COPY --from=build /app/prisma ./prisma
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["node_modules/.bin/next", "start"]
