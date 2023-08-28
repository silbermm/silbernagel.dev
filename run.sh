#!/bin/bash
set -e

# Connect to tailscale
/app/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
/app/tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=silbernageldev-web

# Restore the database if it does not already exist.
if [ -f /sql_data/silbernagel.db ]; then
  echo "Database already exists, skipping restore"
else
  echo "No database found, restoring from replica if exists"
  litestream restore -if-replica-exists /sql_data/silbernagel.db
fi

# Run migrations
/app/bin/migrate

# Run litestream with your app as the subprocess.
exec litestream replicate -exec "/app/bin/server"
#exec /app/bin/server
