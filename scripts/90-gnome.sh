#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_SRC="$ROOT_DIR/gnome/extensions"
EXT_DST="$HOME/.local/share/gnome-shell/extensions"
DCONF_DIR="$ROOT_DIR/gnome/dconf"

mkdir -p "$EXT_DST"

if [ -d "$EXT_SRC" ] && [ "$(find "$EXT_SRC" -mindepth 1 -maxdepth 1 | wc -l)" -gt 0 ]; then
  echo "Copying GNOME extensions..."
  rsync -a --delete "$EXT_SRC/" "$EXT_DST/"
fi

# Compile extension schemas only when XML schemas exist.
find "$EXT_DST" -mindepth 2 -maxdepth 2 -type d -name schemas | while read -r schema_dir; do
  if find "$schema_dir" -maxdepth 1 -name '*.gschema.xml' | grep -q .; then
    glib-compile-schemas "$schema_dir" || true
  fi
done

# Restore only safe/exported dconf subtrees. Do NOT load a full /org/gnome dump:
# some keys are non-writable and will abort the install.
if [ -d "$DCONF_DIR" ]; then
  for file in "$DCONF_DIR"/*.ini; do
    [ -f "$file" ] || continue
    case "$(basename "$file")" in
      interface.ini)       dconf load /org/gnome/desktop/interface/ < "$file" || true ;;
      shell.ini)           dconf load /org/gnome/shell/ < "$file" || true ;;
      shell-extensions.ini)dconf load /org/gnome/shell/extensions/ < "$file" || true ;;
      mutter.ini)          dconf load /org/gnome/mutter/ < "$file" || true ;;
      media-keys.ini)      dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$file" || true ;;
      wm-keybindings.ini)  dconf load /org/gnome/desktop/wm/keybindings/ < "$file" || true ;;
    esac
  done
fi

# Baseline appearance/launcher settings that must always survive.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
gsettings set org.gnome.desktop.interface icon-theme 'Tela-pink-dark' || true
gsettings set org.gnome.mutter overlay-key '' || true

if [ -f "$ROOT_DIR/gnome/enabled-extensions.txt" ]; then
  while read -r ext; do
    [ -z "$ext" ] && continue
    gnome-extensions enable "$ext" || true
  done < "$ROOT_DIR/gnome/enabled-extensions.txt"
fi

echo "GNOME restore done. Log out/in recommended."
