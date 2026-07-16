#!/usr/bin/env bash
set -euo pipefail

STATE_ROOT="$HOME/.local/share/doorstation"
BACKUP_ROOT="$STATE_ROOT/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$BACKUP_ROOT/$STAMP"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"

mkdir -p "$DEST"

# Back up every user extension before managed extensions are copied or updated.
# Restoring this snapshot therefore also restores custom/private extensions.
if [[ -d "$EXT_DIR" ]]; then
  mkdir -p "$DEST/gnome-extensions"
  cp -a "$EXT_DIR/." "$DEST/gnome-extensions/"
fi

gsettings get org.gnome.shell enabled-extensions > "$DEST/enabled-extensions.gvariant" 2>/dev/null || true
gsettings get org.gnome.shell disabled-extensions > "$DEST/disabled-extensions.gvariant" 2>/dev/null || true
dconf dump /org/gnome/ > "$DEST/gnome.dconf" 2>/dev/null || true

for dir in \
  "$HOME/.config/walker" \
  "$HOME/.config/elephant" \
  "$HOME/.config/systemd/user" \
  "$(xdg-user-dir TEMPLATES 2>/dev/null || echo "$HOME/Templates")"
do
  [[ -e "$dir" ]] || continue
  name="$(printf '%s' "$dir" | sed 's#^/##; s#/#__#g')"
  cp -a "$dir" "$DEST/$name"
done

printf '%s\n' "$DEST" > "$STATE_ROOT/latest-backup"
echo "✓ GNOME/user state backup: $DEST"
