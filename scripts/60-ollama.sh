#!/usr/bin/env bash
set -euo pipefail

echo "== Installing Ollama =="

if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

sudo mkdir -p /etc/systemd/system/ollama.service.d

sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null <<'CONF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="HIP_VISIBLE_DEVICES=0"
Environment="ROCR_VISIBLE_DEVICES=0"
Environment="OLLAMA_FLASH_ATTENTION=1"
CONF

sudo systemctl daemon-reload
sudo systemctl enable --now ollama
sudo systemctl restart ollama

echo "Waiting for Ollama API..."
for i in {1..30}; do
  if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "== Starting Open WebUI =="

podman volume create openwebui || true
podman rm -f open-webui >/dev/null 2>&1 || true

podman run -d \
  --name open-webui \
  --network host \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v openwebui:/app/backend/data \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main

echo "== Pulling Ollama models =="

ollama pull qwen2.5-coder:14b || true
ollama pull qwen3-coder:30b || true
ollama pull gemma3:27b || true

echo "Ollama ready: http://localhost:11434"
echo "Open WebUI ready: http://localhost:3000"
