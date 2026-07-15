#!/usr/bin/env bash
set -euo pipefail

check() {
  local name="$1"
  local cmd="$2"

  if bash -lc "$cmd" >/dev/null 2>&1; then
    echo "✓ $name"
  else
    echo "✗ $name"
  fi
}

echo "== Versions =="
command -v code && code --version | head -1 || true
command -v mise && mise --version || true
command -v elixir && elixir -v || true
command -v node && node -v || true
command -v cargo && cargo --version || true

echo
echo "== ROCm =="
if command -v rocminfo >/dev/null 2>&1; then
  rocminfo | grep -E "gfx1100|Radeon RX|Agent" || true
  check "rocminfo" "rocminfo | grep -q 'Agent'"
  check "rocm-smi" "rocm-smi >/dev/null"
  check "hipcc" "hipcc --version >/dev/null"
  check "vulkan" "vulkaninfo >/dev/null"
else
  echo "rocminfo not installed."
fi

echo
echo "== Containers =="
podman ps || true

echo
echo "== Ollama =="
curl -s http://localhost:11434/api/tags || echo "Ollama not running."

echo
echo "== GStreamer =="
gst-inspect-1.0 gtk4paintablesink >/dev/null 2>&1 && echo "gtk4paintablesink OK" || echo "gtk4paintablesink MISSING"
gst-inspect-1.0 avdec_h264 >/dev/null 2>&1 && echo "avdec_h264 OK" || echo "avdec_h264 MISSING"
gst-inspect-1.0 gtkwaylandsink >/dev/null 2>&1 && echo "gtkwaylandsink OK" || echo "gtkwaylandsink MISSING"

echo
echo "== Desktop services =="
check "Elephant service enabled" "systemctl --user is-enabled elephant.service"
check "Walker service enabled" "systemctl --user is-enabled walker.service"
check "UxPlay service enabled" "systemctl --user is-enabled uxplay.service"
check "UxPlay binary" "/usr/local/bin/uxplay -v"
check "Nautilus image extension" "test -f '$HOME/.local/share/nautilus-python/extensions/image_converter.py'"
check "HEIC converter" "command -v heif-convert"
check "ImageMagick" "command -v magick"

echo
echo "== 👌 Original Dev Machien 🤌 =="
echo " 🤮 Rocky Linux configured with DoorAPI dev packages"
echo " 🤮 ROCm userspace installed"
echo " 🤮 Use Super + Space for launcher"
echo " 😵‍💫 Open WebUI: http://localhost:3000"
echo " 🤯 Cockpit: https://localhost:9090"
echo "== 🫠 Happy slapping 🤏 =="