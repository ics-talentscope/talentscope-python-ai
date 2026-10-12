#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

MODEL="${MODEL:-Qwen3.5-4B-Q4_K_M.gguf}"
CTX="${CTX:-2048}"
THREADS="${THREADS:-2}"
PORT="${PORT:-8080}"
HOST="${HOST:-127.0.0.1}"
BIN="${BIN:-llamafile-0.10.5.exe}"
KEY_FILE="${KEY_FILE:-.llm-api-key}"

[[ -f "$MODEL" ]] || { echo "Missing model file: $MODEL"; exit 1; }
[[ -f "$KEY_FILE" ]] || { echo "Missing $KEY_FILE (must match LOCAL_LLM_API_KEY)"; exit 1; }

chmod +x "$BIN" 2>/dev/null || true
KEY="$(tr -d '\r\n' < "$KEY_FILE")"
printf '{"apiKey":"%s"}' "$KEY" > .llm-ui-config.json
chmod 600 .llm-ui-config.json

exec "./$BIN" \
  --server \
  --host "$HOST" \
  --port "$PORT" \
  --model "$MODEL" \
  --ctx-size "$CTX" \
  --threads "$THREADS" \
  --parallel 1 \
  --gpu disable \
  --reasoning off \
  --reasoning-budget 0 \
  --chat-template-kwargs '{"enable_thinking":false}' \
  --api-key-file "$KEY_FILE" \
  --ui-config-file ".llm-ui-config.json"
