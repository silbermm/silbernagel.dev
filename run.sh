#!/bin/bash
set -e

# connect to my tailnet
#/app/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
#/app/tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=silbernagel-dev-service

# Restore the database if it does not already exist.
if [ -f /data/silbernageldev.db ]; then
  echo "Database already exists, skipping restore"
else
  echo "No database found, restoring from replica if exists"
  #litestream restore -v -if-replica-exists -o /data/silbernageldev.db "${REPLICA_URL}"
fi

# Run migrations
/app/bin/migrate

# Run litestream with your app as the subprocess.
#exec litestream replicate -exec "/app/bin/server"
exec /app/bin/server
