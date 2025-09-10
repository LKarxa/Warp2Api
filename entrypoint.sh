#!/usr/bin/env sh
set -e

SERVICE="${SERVICE:-bridge}"

echo "[entrypoint] Selected SERVICE=${SERVICE}"

case "$SERVICE" in
  bridge)
    exec python server.py
    ;;
  openai)
    exec python openai_compat.py
    ;;
  all)
    python server.py &
    BRIDGE_PID=$!
    echo "[entrypoint] bridge started pid=${BRIDGE_PID}"
    # give the bridge a moment to bind the port (best-effort)
    sleep 0.5 || true
    python openai_compat.py &
    OPENAI_PID=$!
    echo "[entrypoint] openai-compat started pid=${OPENAI_PID}"
    # poll for either process to exit (POSIX sh lacks wait -n)
    while :; do
      if ! kill -0 "$BRIDGE_PID" 2>/dev/null; then
        wait "$BRIDGE_PID"
        STATUS=$?
        echo "[entrypoint] bridge exited with status ${STATUS}, stopping openai"
        kill "$OPENAI_PID" 2>/dev/null || true
        exit "$STATUS"
      fi
      if ! kill -0 "$OPENAI_PID" 2>/dev/null; then
        wait "$OPENAI_PID"
        STATUS=$?
        echo "[entrypoint] openai-compat exited with status ${STATUS}, stopping bridge"
        kill "$BRIDGE_PID" 2>/dev/null || true
        exit "$STATUS"
      fi
      sleep 1
    done
    ;;
  *)
    echo "[entrypoint] Unrecognized SERVICE=$SERVICE, running as raw command: $*"
    exec "$@"
    ;;
esac
