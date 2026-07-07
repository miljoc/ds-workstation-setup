#!/usr/bin/env bash
set -euo pipefail

EXTENSIONS=(
  lexical-lsp.lexical
  ms-kubernetes-tools.vscode-kubernetes-tools
  ms-azuretools.vscode-containers
  phoenixframework.phoenix
  bradlc.vscode-tailwindcss
  redhat.vscode-yaml
  ms-vscode.makefile-tools
  eamodio.gitlens
  usernamehw.errorlens
  gruntfuggly.todo-tree
  editorconfig.editorconfig
  tamasfe.even-better-toml
  yzhang.markdown-all-in-one
)

for ext in "${EXTENSIONS[@]}"; do
  code --install-extension "$ext" || true
done

if pgrep -x ollama >/dev/null 2>&1 || systemctl is-active --quiet ollama; then
  code --install-extension saoudrizwan.claude-dev || true
fi

mkdir -p "$HOME/doorapi/.vscode"

cat > "$HOME/doorapi/.vscode/settings.json" <<'JSON'
{
  "editor.formatOnSave": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,

  "[elixir]": {
    "editor.defaultFormatter": "lexical-lsp.lexical"
  },
  "[phoenix-heex]": {
    "editor.defaultFormatter": "lexical-lsp.lexical"
  },

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
JSON
