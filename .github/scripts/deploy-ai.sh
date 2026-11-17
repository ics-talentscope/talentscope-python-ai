#!/usr/bin/env bash
set -euo pipefail

# Deploy talentscope-python-ai into the shared /opt/AI stack used by prod + dev.
# Repo layout: faceproj/, qwen/
# VM layout:   /opt/AI/faceproj, /opt/AI/Qwen

if [[ -z "${GITHUB_SHA:-}" ]]; then
  echo "GITHUB_SHA is required; run this script from the AI workflow." >&2
  exit 1
fi

SRC="$(git rev-parse --show-toplevel)"
AI_ROOT="${AI_ROOT:-/opt/AI}"
FACE_DIR="$AI_ROOT/faceproj"
QWEN_DIR="$AI_ROOT/Qwen"
SHA="${GITHUB_SHA:0:12}"
LOCK_FILE=/tmp/talentscope-ai-deploy.lock

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "Another TalentScope AI deployment is running; retry after it finishes." >&2
  exit 1
fi

[[ -d "$SRC/faceproj" ]] || { echo "Missing faceproj/ in repository root." >&2; exit 1; }
[[ -d "$SRC/qwen" ]] || { echo "Missing qwen/ in repository root." >&2; exit 1; }

echo "== Sync FaceNet $SHA -> $FACE_DIR"
sudo mkdir -p "$FACE_DIR" "$QWEN_DIR"
sudo chown -R "$(id -un):$(id -gn)" "$AI_ROOT"
rsync -a --delete --checksum \
  --exclude='/.venv/' --exclude='/venv/' --exclude='/.git/' \
  --exclude='/**/__pycache__/' --exclude='*.pyc' \
  --exclude='/haarcascade_frontalface_default .xml' \
  "$SRC/faceproj/" "$FACE_DIR/"

echo "== Sync Qwen scripts $SHA -> $QWEN_DIR (preserve model/binaries)"
rsync -a --checksum \
  --exclude='/.git/' \
  --exclude='*.gguf' \
  --exclude='llamafile*' \
  --exclude='.ape-*' \
  --exclude='.llm-api-key' \
  --exclude='.llm-ui-config.json' \
  "$SRC/qwen/" "$QWEN_DIR/"
chmod +x "$QWEN_DIR/start.sh" 2>/dev/null || true

wait_http_ok() {
  local url="$1" label="$2" attempts="${3:-60}" sleep_s="${4:-5}"
  local i code
  for i in $(seq 1 "$attempts"); do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" || true)"
    if [[ "$code" == "200" ]]; then
      echo "$label healthy ($url)"
      return 0
    fi
    echo "waiting for $label ($i/$attempts) http=$code"
    sleep "$sleep_s"
  done
  echo "$label did not become healthy: $url" >&2
  return 1
}

echo "== Restart FaceNet"
sudo systemctl restart facenet
if ! wait_http_ok "http://172.17.0.1:10000/health" "FaceNet" 36 5; then
  journalctl -u facenet -n 40 --no-pager || true
  exit 1
fi

echo "== Restart Qwen (model load can take several minutes)"
sudo systemctl restart qwen
# Prefer /health; fall back to /v1/models. Allow ~5 minutes.
ok=0
for i in $(seq 1 60); do
  if curl -fsS -m 5 http://127.0.0.1:8080/health >/dev/null 2>&1; then ok=1; break; fi
  if curl -fsS -m 5 http://127.0.0.1:8080/v1/models >/dev/null 2>&1; then ok=1; break; fi
  echo "waiting for Qwen ($i/60)"
  sleep 5
done
if [[ "$ok" -ne 1 ]]; then
  echo "Qwen health check failed" >&2
  journalctl -u qwen -n 40 --no-pager || true
  exit 1
fi
echo "Qwen healthy"

printf '%s\n' "$SHA" > "$AI_ROOT/DEPLOYED_COMMIT"
echo "== AI deployment OK: $SHA (FaceNet :10000, Qwen :8080)"