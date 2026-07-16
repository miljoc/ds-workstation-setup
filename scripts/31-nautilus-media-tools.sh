#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_DIR="$HOME/.local/share/nautilus-python/extensions"

sudo dnf install -y \
  nautilus-python ImageMagick libnotify ffmpeg \
  tesseract tesseract-langpack-eng tesseract-langpack-nld \
  zbar poppler-utils wl-clipboard perl-Image-ExifTool

if ! command -v heif-convert >/dev/null 2>&1; then
  sudo dnf install -y libheif-tools || sudo dnf install -y libheif
fi
mkdir -p "$EXT_DIR"
rm -f "$EXT_DIR/image_converter.py" "$EXT_DIR/video_converter.py"
install -m 0644 "$ROOT_DIR/nautilus/workstation_tools.py" "$EXT_DIR/workstation_tools.py"
python3 -m py_compile "$EXT_DIR/workstation_tools.py"
nautilus -q >/dev/null 2>&1 || true

echo "Workstation Tools installed: $EXT_DIR/workstation_tools.py"
