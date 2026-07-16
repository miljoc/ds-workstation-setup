#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_SRC="$ROOT_DIR/gnome/extensions"
EXT_DST="$HOME/.local/share/gnome-shell/extensions"
DCONF_DIR="$ROOT_DIR/gnome/dconf"

mkdir -p "$EXT_DST"
BUNDLED_STATE="$HOME/.local/state/doorsecure-workstation/bundled-gnome-extensions.txt"
mkdir -p "$(dirname "$BUNDLED_STATE")"
: > "$BUNDLED_STATE"

if [ -d "$EXT_SRC" ] && [ "$(find "$EXT_SRC" -mindepth 1 -maxdepth 1 | wc -l)" -gt 0 ]; then
  echo "Copying GNOME extensions..."
  # Do not use --delete here: extensions downloaded earlier in this same setup
  # run must not be removed by the bundled-extension restore.
  while IFS= read -r src; do
    uuid="$(basename "$src")"
    mkdir -p "$EXT_DST/$uuid"
    rsync -a "$src/" "$EXT_DST/$uuid/"
    echo "$uuid" >> "$BUNDLED_STATE"
    echo "  ✓ Bundled/custom extension restored: $uuid"
  done < <(find "$EXT_SRC" -mindepth 1 -maxdepth 1 -type d | sort)
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

enable_extension_persistently() {
  local uuid="$1"
  gnome-extensions enable "$uuid" >/dev/null 2>&1 || true
  python3 - "$uuid" <<'PYENABLE'
import ast
import subprocess
import sys
uuid = sys.argv[1]
try:
    raw = subprocess.check_output(
        ["gsettings", "get", "org.gnome.shell", "enabled-extensions"],
        text=True,
    ).strip()
    if raw.startswith("@as "):
        raw = raw[4:]
    values = list(ast.literal_eval(raw))
except Exception:
    values = []
if uuid not in values:
    values.append(uuid)
formatted = "[" + ", ".join(repr(value) for value in values) + "]"
subprocess.run(
    ["gsettings", "set", "org.gnome.shell", "enabled-extensions", formatted],
    check=False,
)
PYENABLE
}

gsettings set org.gnome.shell disable-user-extensions false || true

# Enable bundled extensions copied from this private workstation repository.
if [[ -f "$BUNDLED_STATE" ]]; then
  while read -r ext; do
    [[ -n "$ext" ]] || continue
    enable_extension_persistently "$ext"
  done < "$BUNDLED_STATE"
fi

# Restore the previously exported extension list.
if [ -f "$ROOT_DIR/gnome/enabled-extensions.txt" ]; then
  while read -r ext; do
    [ -z "$ext" ] && continue
    enable_extension_persistently "$ext"
  done < "$ROOT_DIR/gnome/enabled-extensions.txt"
fi

# Re-enable extensions downloaded by scripts/89-gnome-extensions.sh. The
# bundled extension restore above must never erase or disable these.
STATE_FILE="$HOME/.local/state/doorsecure-workstation/installed-gnome-extensions.txt"
if [ -f "$STATE_FILE" ]; then
  while read -r ext; do
    [ -z "$ext" ] && continue
    enable_extension_persistently "$ext"
  done < "$STATE_FILE"
fi

echo "GNOME restore done. New extensions will load after one log out/in."
