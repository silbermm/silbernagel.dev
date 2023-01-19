#!/bin/bash
set -e

# Run migrations
/app/bin/migrate

# Run litestream with your app as the subprocess.
#exec litestream replicate -exec "/app/bin/server"
exec /app/bin/server
