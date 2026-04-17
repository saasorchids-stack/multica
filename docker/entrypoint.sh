#!/bin/sh
set -e

echo "Running database migrations..."
./migrate up

# Start the daemon in background if auth token is provided and at least
# one agent CLI is available. The daemon connects to the server running
# in this same container via localhost.
if [ -n "$MULTICA_AUTH_TOKEN" ]; then
  HAS_AGENT=false
  command -v claude >/dev/null 2>&1 && HAS_AGENT=true
  command -v codex  >/dev/null 2>&1 && HAS_AGENT=true

  if [ "$HAS_AGENT" = "true" ]; then
    echo "Starting agent daemon..."
    MULTICA_SERVER_URL="http://localhost:${PORT:-8080}" \
      ./multica daemon start --foreground &
    DAEMON_PID=$!
    echo "Daemon started (PID=$DAEMON_PID)"
  else
    echo "WARN: MULTICA_AUTH_TOKEN set but no agent CLI found (install claude or codex)"
  fi
else
  echo "INFO: Daemon disabled — set MULTICA_AUTH_TOKEN to enable agent execution"
fi

echo "Starting server..."
exec ./server
