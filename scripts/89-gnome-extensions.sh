#!/usr/bin/env bash
set -euo pipefail

sudo dnf install -y curl unzip python3 glib2 gnome-extensions-app

SHELL_VERSION="$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)"
SHELL_VERSION="${SHELL_VERSION:-49}"
EXT_ROOT="$HOME/.local/share/gnome-shell/extensions"
STATE_DIR="$HOME/.local/state/doorstation"
STATE_FILE="$STATE_DIR/installed-gnome-extensions.txt"
mkdir -p "$EXT_ROOT" "$STATE_DIR"
touch "$STATE_FILE"

gsettings set org.gnome.shell disable-user-extensions false || true

enable_extension_persistently() {
  local uuid="$1"

  # This may only become effective after the next GNOME Shell login, but it is
  # still useful for an already-known extension.
  gnome-extensions enable "$uuid" >/dev/null 2>&1 || true

  # Persist the UUID directly in GNOME's enabled-extensions setting. This works
  # even when the running shell has not reloaded the newly installed extension.
  python3 - "$uuid" <<'PY'
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
    enabled = list(ast.literal_eval(raw))
except Exception:
    enabled = []

if uuid not in enabled:
    enabled.append(uuid)

value = "[" + ", ".join(repr(item) for item in enabled) + "]"
subprocess.run(
    ["gsettings", "set", "org.gnome.shell", "enabled-extensions", value],
    check=False,
)
PY

  grep -Fxq "$uuid" "$STATE_FILE" || echo "$uuid" >> "$STATE_FILE"
}

install_ego_extension() {
  local id="$1"
  local label="$2"
  local info_file zip_file download_url uuid
  info_file="$(mktemp)"
  zip_file="$(mktemp --suffix=.zip)"

  echo "→ $label (EGO #$id)"
  if ! curl -fsSL "https://extensions.gnome.org/extension-info/?pk=${id}&shell_version=${SHELL_VERSION}" -o "$info_file"; then
    echo "  ⚠ Kon extensie-informatie niet downloaden; overslaan."
    rm -f "$info_file" "$zip_file"
    return 0
  fi

  readarray -t values < <(python3 - "$info_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    data = json.load(handle)
print(data.get('download_url', ''))
print(data.get('uuid', ''))
PY
)
  download_url="${values[0]:-}"
  uuid="${values[1]:-}"

  if [[ -z "$download_url" || -z "$uuid" ]]; then
    echo "  ⚠ Geen compatibele versie voor GNOME Shell $SHELL_VERSION gevonden; overslaan."
    rm -f "$info_file" "$zip_file"
    return 0
  fi

  [[ "$download_url" =~ ^https?:// ]] || download_url="https://extensions.gnome.org${download_url}"
  if ! curl -fsSL "$download_url" -o "$zip_file"; then
    echo "  ⚠ Download mislukt; overslaan."
    rm -f "$info_file" "$zip_file"
    return 0
  fi

  rm -rf "$EXT_ROOT/$uuid"
  mkdir -p "$EXT_ROOT/$uuid"
  unzip -q "$zip_file" -d "$EXT_ROOT/$uuid"

  if [[ -d "$EXT_ROOT/$uuid/schemas" ]] && find "$EXT_ROOT/$uuid/schemas" -maxdepth 1 -name '*.gschema.xml' | grep -q .; then
    glib-compile-schemas "$EXT_ROOT/$uuid/schemas" || true
  fi

  enable_extension_persistently "$uuid"

  if grep -Fq "$uuid" < <(gsettings get org.gnome.shell enabled-extensions); then
    echo "  ✓ Geinstalleerd en voor volgende login ingeschakeld: $uuid"
  else
    echo "  ⚠ Geinstalleerd, maar kon enabled-extensions niet aanpassen: $uuid"
  fi

  rm -f "$info_file" "$zip_file"
}

install_ego_extension 8243  "UXPlay Control"
install_ego_extension 10076 "Medialine"
install_ego_extension 1319  "GSConnect"
install_ego_extension 7024  "Custom Command Menu"
install_ego_extension 6697  "ClipQR"

if [[ "${INSTALL_ROCM:-N}" == "Y" ]]; then
  install_ego_extension 9496 "ROCm GPU Monitor"
else
  echo "↷ ROCm GPU Monitor overgeslagen omdat ROCm niet is geselecteerd."
fi

echo
echo "GNOME-extensies zijn geinstalleerd en persistent ingeschakeld."
echo "Meld eenmalig af en weer aan zodat GNOME Shell de nieuwe extensies laadt."
