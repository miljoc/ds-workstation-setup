#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GNOME_DIR="$ROOT_DIR/gnome"
DCONF_DIR="$GNOME_DIR/dconf"
EXT_SRC="$HOME/.local/share/gnome-shell/extensions"
EXT_DST="$GNOME_DIR/extensions"

mkdir -p "$GNOME_DIR" "$DCONF_DIR" "$EXT_DST"

# Export only writable/stable GNOME subtrees. A full /org/gnome dump can contain
# non-writable keys and break unattended restores.
dconf dump /org/gnome/desktop/interface/ > "$DCONF_DIR/interface.ini"
dconf dump /org/gnome/shell/ > "$DCONF_DIR/shell.ini"
dconf dump /org/gnome/shell/extensions/ > "$DCONF_DIR/shell-extensions.ini"
dconf dump /org/gnome/mutter/ > "$DCONF_DIR/mutter.ini"
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > "$DCONF_DIR/media-keys.ini"
dconf dump /org/gnome/desktop/wm/keybindings/ > "$DCONF_DIR/wm-keybindings.ini"

gnome-extensions list --enabled > "$GNOME_DIR/enabled-extensions.txt"

rsync -a --delete \
  --exclude='schemas/gschemas.compiled' \
  "$EXT_SRC/" "$EXT_DST/"

find "$EXT_DST" -type d -name schemas | while read -r schema_dir; do
  if find "$schema_dir" -maxdepth 1 -name '*.gschema.xml' | grep -q .; then
    glib-compile-schemas "$schema_dir" || true
  fi
done

echo "Exported GNOME config to: $GNOME_DIR"
echo "- $DCONF_DIR/*.ini"
echo "- $GNOME_DIR/enabled-extensions.txt"
echo "- $GNOME_DIR/extensions/"
