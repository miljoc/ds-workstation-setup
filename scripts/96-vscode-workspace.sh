#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOORAPI_DIR="$HOME/doorapi"
WORKSPACE_FILE="$DOORAPI_DIR/doorapi.code-workspace"

echo "== Creating DoorAPI VS Code workspace =="

mkdir -p "$DOORAPI_DIR/.vscode" "$DOORAPI_DIR/.clinerules"

# Copy VS Code config into the workspace root.
if [ -d "$ROOT_DIR/vscode" ]; then
  for f in settings.json tasks.json launch.json keybindings.json extensions.json; do
    [ -f "$ROOT_DIR/vscode/$f" ] && cp -f "$ROOT_DIR/vscode/$f" "$DOORAPI_DIR/.vscode/$f"
  done
fi

# Copy Cline rules into the workspace root.
if [ -d "$ROOT_DIR/clinerules" ]; then
  rsync -a --delete "$ROOT_DIR/clinerules/" "$DOORAPI_DIR/.clinerules/"
fi

# Install VS Code extensions from extensions.json or extensions.txt when available.
if command -v code >/dev/null 2>&1; then
  if [ -f "$ROOT_DIR/vscode/extensions.txt" ]; then
    while read -r ext; do
      [ -z "$ext" ] && continue
      code --install-extension "$ext" || true
    done < "$ROOT_DIR/vscode/extensions.txt"
  elif [ -f "$ROOT_DIR/vscode/extensions.json" ]; then
    python3 - "$ROOT_DIR/vscode/extensions.json" <<'PY' | while read -r ext; do
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
for ext in data.get('recommendations', []):
    print(ext)
PY
      [ -z "$ext" ] && continue
      code --install-extension "$ext" || true
    done
  fi
fi

python3 - "$DOORAPI_DIR" "$WORKSPACE_FILE" <<'PY'
import json
import os
import sys

doorapi_dir = sys.argv[1]
workspace_file = sys.argv[2]
repo_names = [
    "device_api",
    "doorapi_front",
    "thirdparty_api",
    "doorapi_mobile",
    "doorapi-k8s",
    "doorapi-dev-local",
]

folders = []
for name in repo_names:
    if os.path.isdir(os.path.join(doorapi_dir, name)):
        folders.append({"name": name, "path": name})

workspace = {
    "folders": folders,
    "settings": {
        "editor.formatOnSave": True,
        "files.trimTrailingWhitespace": True,
        "files.insertFinalNewline": True,
        "[elixir]": {"editor.defaultFormatter": "lexical-lsp.lexical"},
        "[phoenix-heex]": {"editor.defaultFormatter": "lexical-lsp.lexical"},
        "files.associations": {
            "*.heex": "phoenix-heex",
            "*.leex": "phoenix-heex",
            "*.sface": "phoenix-heex"
        },
        "emmet.includeLanguages": {
            "phoenix-heex": "html",
            "elixir": "html"
        },
        "tailwindCSS.includeLanguages": {
            "phoenix-heex": "html",
            "elixir": "html"
        }
    }
}

with open(workspace_file, "w", encoding="utf-8") as f:
    json.dump(workspace, f, indent=2)
    f.write("\n")
PY

echo "Workspace created: $WORKSPACE_FILE"
