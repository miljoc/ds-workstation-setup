#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_SETTINGS_DIR="$HOME/.config/Code/User"
GLOBAL_SETTINGS_FILE="$GLOBAL_SETTINGS_DIR/settings.json"

# Expert is the only Elixir language server managed by Doorstation.
# Remove conflicting/deprecated extensions to avoid duplicate commands,
# formatters, diagnostics and the "command Reindex already exists" crash.
CONFLICTING_EXTENSIONS=(
  lexical-lsp.lexical
  JakeBecker.elixir-ls
  jakebecker.elixir-ls
  pantajoe.vscode-elixir-credo
)

EXTENSIONS=(
  ExpertLSP.expert
  ms-kubernetes-tools.vscode-kubernetes-tools
  ms-azuretools.vscode-containers
  phoenixframework.phoenix
  bradlc.vscode-tailwindcss
  esbenp.prettier-vscode
  redhat.vscode-yaml
  ms-vscode.makefile-tools
  eamodio.gitlens
  usernamehw.errorlens
  gruntfuggly.todo-tree
  editorconfig.editorconfig
  tamasfe.even-better-toml
  yzhang.markdown-all-in-one
)

if ! command -v code >/dev/null 2>&1; then
  echo "VS Code CLI not found; skipping VS Code configuration."
  exit 0
fi

for ext in "${CONFLICTING_EXTENSIONS[@]}"; do
  code --uninstall-extension "$ext" >/dev/null 2>&1 || true
done

for ext in "${EXTENSIONS[@]}"; do
  code --install-extension "$ext" --force || true
done

mkdir -p "$GLOBAL_SETTINGS_DIR" "$HOME/doorapi/.vscode"

# Preserve the previous global settings before installing the managed baseline.
if [[ -f "$GLOBAL_SETTINGS_FILE" ]]; then
  cp -f "$GLOBAL_SETTINGS_FILE" "$GLOBAL_SETTINGS_FILE.doorstation-backup"
fi
cp -f "$ROOT_DIR/vscode/settings.json" "$GLOBAL_SETTINGS_FILE"
cp -f "$ROOT_DIR/vscode/settings.json" "$HOME/doorapi/.vscode/settings.json"
cp -f "$ROOT_DIR/vscode/extensions.json" "$HOME/doorapi/.vscode/extensions.json"

echo "VS Code configured for Expert LSP."
echo "Global settings: $GLOBAL_SETTINGS_FILE"
echo "Previous settings backup: $GLOBAL_SETTINGS_FILE.doorstation-backup"
