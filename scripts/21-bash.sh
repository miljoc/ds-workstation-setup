#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== Installing DoorAPI bash config =="

sudo dnf install -y bash-completion fzf ripgrep fd-find bat || true

mkdir -p "$HOME/.config/bash"

if [ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.bashrc.backup-doorapi" ]; then
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup-doorapi"
fi

cp "$ROOT_DIR/bash/bashrc" "$HOME/.bashrc"
cp "$ROOT_DIR/bash/doorapi-shell.sh" "$HOME/.config/bash/doorapi-shell.sh"

echo "Bash configured."
echo "Open a new terminal or run: source ~/.bashrc"
