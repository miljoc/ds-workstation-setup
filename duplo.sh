#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/miljoc/ds-workstation-setup.git}"
TARGET_DIR="${TARGET_DIR:-$HOME/doorapi-dev-machien}"

echo "== 🔥🔥🔥 🇺🇸 Almighty Jeff ✝️ and Mike Row Soft 🇨🇳 presents 🔥🔥🔥 =="
echo "== 🥁🥁🥁 AAAAAND ITS NAME ISSSSSS 🥁🥁🥁 =="
echo "== 🤮 DoorAPI Dev Machien 🤢 =="
echo "== 🦌 Based on GNU/LINUX 🐧 =="
echo "== 🕉️ BECAME HIGHER THEN GOD HIMSELF WITH THIS ALMIGHTY SCRIPT 🦅 =="
echo "== 🇳🇱🇳🇱🇳🇱 Your system will now be GEKOLONISEERD 🇳🇱🇳🇱🇳🇱 =="

if ! command -v git >/dev/null 2>&1; then
  sudo dnf install -y git
fi

if [ -d "$TARGET_DIR/.git" ]; then
  echo "Repo already exists. Pulling latest..."
  git -C "$TARGET_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"

chmod +x install.sh scripts/*.sh

./install.sh