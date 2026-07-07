#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

echo "== Configuring Super+Space for Walker =="

WALKER_BIN="$(command -v walker || true)"
if [ -z "$WALKER_BIN" ] && [ -x "$HOME/.local/bin/walker" ]; then
  WALKER_BIN="$HOME/.local/bin/walker"
fi

if [ -z "$WALKER_BIN" ]; then
  echo "ERROR: Walker not found. Run scripts/91-launcher.sh first."
  exit 1
fi

# Disable the normal Super overview.
gsettings set org.gnome.mutter overlay-key '' || true

# Disable GNOME input source shortcuts that conflict with Super+Space.
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]" || true
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]" || true

CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/walker/"
CURRENT="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"

python3 - "$CURRENT" "$CUSTOM_PATH" <<'PY' > /tmp/doorapi-custom-keybindings.txt
import ast
import sys
current = sys.argv[1]
path = sys.argv[2]
try:
    items = ast.literal_eval(current.replace('@as ', ''))
except Exception:
    items = []
if path not in items:
    items.append(path)
print(str(items).replace('"', "'"))
PY

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$(cat /tmp/doorapi-custom-keybindings.txt)"

SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH"
gsettings set "$SCHEMA" name "Walker"
gsettings set "$SCHEMA" command "$WALKER_BIN"
gsettings set "$SCHEMA" binding "<Super>space"

echo
echo "Configured: Super+Space -> Walker"
gsettings list-recursively "$SCHEMA"
