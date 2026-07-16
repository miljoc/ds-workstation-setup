#!/usr/bin/env bash
set -u

check() {
  local name="$1"
  local cmd="$2"
  if bash -lc "$cmd" >/dev/null 2>&1; then
    echo "✓ $name"
  else
    echo "✗ $name"
  fi
}

check_file() {
  local path="$1"
  local name="$2"
  [[ -f "$path" ]] && echo "✓ $name" || echo "✗ $name"
}

echo "== Versions =="
command -v code >/dev/null && code --version | head -1 || true
command -v mise >/dev/null && mise --version || true
command -v elixir >/dev/null && elixir -v || true
command -v node >/dev/null && node -v || true
command -v cargo >/dev/null && cargo --version || true

echo
echo "== ROCm =="
if command -v rocminfo >/dev/null 2>&1; then
  check "rocminfo" "rocminfo | grep -q Agent"
  check "rocm-smi" "rocm-smi >/dev/null"
  check "hipcc" "hipcc --version >/dev/null"
else
  echo "↷ ROCm niet geinstalleerd."
fi

echo
echo "== Containers =="
command -v podman >/dev/null 2>&1 && podman ps || true

echo
echo "== GStreamer =="
check "gtk4paintablesink" "gst-inspect-1.0 gtk4paintablesink"
check "avdec_h264" "gst-inspect-1.0 avdec_h264"
check "gtkwaylandsink" "gst-inspect-1.0 gtkwaylandsink"
check "VP8 decoder" "gst-inspect-1.0 vp8dec"
check "VP9 decoder" "gst-inspect-1.0 vp9dec"

echo
echo "== Desktop services =="
check "Elephant service enabled" "systemctl --user is-enabled elephant.service"
check "Elephant service active" "systemctl --user is-active elephant.service"
check "Elephant responsive" "$HOME/.local/bin/elephant listproviders >/dev/null"
check "Walker service enabled" "systemctl --user is-enabled walker.service"
check "Walker service active" "systemctl --user is-active walker.service"
check "UxPlay service enabled" "systemctl --user is-enabled uxplay.service"
check "UxPlay binary" "/usr/local/bin/uxplay -v"
check_file "$HOME/.local/share/nautilus-python/extensions/workstation_tools.py" "Nautilus Workstation Tools"
check "Tesseract OCR" "command -v tesseract"
check "QR scanner" "command -v zbarimg"
check "FFmpeg" "command -v ffmpeg"
check "HEIC converter" "command -v heif-convert"
check "ImageMagick" "command -v magick"

TEMPLATE_DIR="$(xdg-user-dir TEMPLATES 2>/dev/null || true)"
TEMPLATE_DIR="${TEMPLATE_DIR:-$HOME/Templates}"
check "Nautilus template groups" "test -d '$TEMPLATE_DIR/General'"

echo
echo "== GNOME extensions =="
for uuid in \
  shotzy@SamkitJain660.github.io \
  uxplay-control@xxanqw \
  clipqr@drien.com
do
  if [[ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ]]; then
    echo "✓ $uuid"
  else
    echo "↷ $uuid niet geinstalleerd"
  fi
done

echo
echo "== Workstation klaar =="
echo "Walker: Super + Space"
echo "Open WebUI: http://localhost:3000 (indien geselecteerd)"
echo "Cockpit: https://localhost:9090"

echo
echo "GNOME extension activation:"
gsettings get org.gnome.shell disable-user-extensions 2>/dev/null | sed 's/^/  disable-user-extensions: /' || true
gsettings get org.gnome.shell enabled-extensions 2>/dev/null | sed 's/^/  enabled-extensions: /' || true
STATE_FILE="$HOME/.local/state/doorstation/installed-gnome-extensions.txt"
if [[ -f "$STATE_FILE" ]]; then
  while read -r uuid; do
    [[ -n "$uuid" ]] || continue
    if [[ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ]]; then
      echo "  ✓ installed: $uuid"
    else
      echo "  ✗ missing: $uuid"
    fi
  done < "$STATE_FILE"
fi

echo
echo "== Bundled and custom GNOME extensions =="
BUNDLED_STATE="$HOME/.local/state/doorstation/bundled-gnome-extensions.txt"
if [[ -s "$BUNDLED_STATE" ]]; then
  while IFS= read -r uuid; do
    [[ -n "$uuid" ]] || continue
    if [[ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ]]; then
      if grep -Fq "$uuid" < <(gsettings get org.gnome.shell enabled-extensions 2>/dev/null); then
        echo "✓ bundled enabled: $uuid"
      else
        echo "⚠ bundled installed but not enabled: $uuid"
      fi
    else
      echo "✗ bundled missing: $uuid"
    fi
  done < "$BUNDLED_STATE"
fi

CUSTOM_COUNT=0
while IFS= read -r path; do
  uuid="$(basename "$path")"
  if { [[ -s "$STATE_FILE" ]] && grep -Fxq "$uuid" "$STATE_FILE"; } || { [[ -s "$BUNDLED_STATE" ]] && grep -Fxq "$uuid" "$BUNDLED_STATE"; }; then
    continue
  fi
  CUSTOM_COUNT=$((CUSTOM_COUNT + 1))
  echo "✓ preserved user/custom: $uuid"
done < <(find "$HOME/.local/share/gnome-shell/extensions" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
[[ "$CUSTOM_COUNT" -gt 0 ]] || echo "↷ Geen extra custom extensions gevonden."
