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

echo "== Restart FaceNet"
sudo systemctl restart facenet
sleep 5
for i in $(seq 1 36); do
  if curl -fsS -m 3 http://172.17.0.1:10000/health >/dev/null 2>&1; then
    echo "FaceNet healthy"
    break
  fi
  if [[ "$i" -eq 36 ]]; then
    echo "FaceNet did not become healthy" >&2
    journalctl -u facenet -n 40 --no-pager || true
    exit 1
  fi
  sleep 5
done

echo "== Ensure Qwen is running"
sudo systemctl restart qwen || true
sleep 3
curl -fsS -m 5 http://127.0.0.1:8080/health >/dev/null || curl -fsS -m 5 http://127.0.0.1:8080/v1/models >/dev/null || {
  echo "Qwen health check failed" >&2
  journalctl -u qwen -n 40 --no-pager || true
  exit 1
}

printf '%s\n' "$SHA" > "$AI_ROOT/DEPLOYED_COMMIT"
echo "== AI deployment OK: $SHA (FaceNet :10000, Qwen :8080)"