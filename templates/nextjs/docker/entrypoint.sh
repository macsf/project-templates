#!/bin/sh
# Drop to HOST_UID:HOST_GID when running as root, chown /data for SQLite,
# then prisma migrate deploy and exec the CMD.
set -eu

if [ "$(id -u)" = "0" ]; then
  TARGET_UID="${HOST_UID:-0}"
  TARGET_GID="${HOST_GID:-0}"
  mkdir -p /data /home/app

  case "$TARGET_UID" in
    ""|*[!0-9]*) TARGET_UID=0 ;;
  esac
  case "$TARGET_GID" in
    ""|*[!0-9]*) TARGET_GID=0 ;;
  esac

  if [ "$TARGET_UID" != "0" ]; then
    groupmod -o -g "$TARGET_GID" node 2>/dev/null || true
    usermod -o -u "$TARGET_UID" -g "$TARGET_GID" node 2>/dev/null || true
    chown -R "$TARGET_UID:$TARGET_GID" /data /home/app
    export HOME=/home/app
    exec gosu node "$0" "$@"
  fi
fi

if [ -d prisma ]; then
  echo "Applying Prisma migrations..."
  ./node_modules/.bin/prisma migrate deploy
fi

echo "Starting..."
exec "$@"
