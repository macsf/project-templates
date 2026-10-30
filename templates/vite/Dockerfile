# syntax=docker/dockerfile:1
# Vite SPA + Express API. Runtime serves dist/ from Express. MySQL is external.

ARG NODE_VERSION={{NODE_VERSION}}

FROM node:${NODE_VERSION}-bookworm-slim AS base

ENV PNPM_HOME=/pnpm \
    PATH=/pnpm:$PATH \
    HUSKY=0 \
    CI=true

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates openssl gosu \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --ignore-scripts

FROM deps AS build
ARG VITE_GOOGLE_CLIENT_ID=
ARG VITE_API_BASE_URL=/api
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID \
    VITE_API_BASE_URL=$VITE_API_BASE_URL \
    DATABASE_URL="mysql://build:build@127.0.0.1:3306/build" \
    NODE_ENV=production
COPY . .
RUN pnpm exec prisma generate \
  && pnpm run build

FROM base AS runtime
WORKDIR /app

ENV NODE_ENV=production \
    PORT=8080 \
    HOST_UID=0 \
    HOST_GID=0 \
    HOME=/home/app

RUN mkdir -p /home/app

COPY --from=build /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/build ./build
COPY --from=build /app/prisma ./prisma
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8080)+'/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "build/server/index.js"]
