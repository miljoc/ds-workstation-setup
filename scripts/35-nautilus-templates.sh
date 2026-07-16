#!/usr/bin/env bash
set -euo pipefail
TEMPLATE_DIR="$(xdg-user-dir TEMPLATES 2>/dev/null || true)"
if [[ -z "$TEMPLATE_DIR" || "$TEMPLATE_DIR" == "$HOME" ]]; then TEMPLATE_DIR="$HOME/Templates"; fi
mkdir -p "$TEMPLATE_DIR"/{General,Development,DoorAPI,Kubernetes}

write() { local path="$1"; shift; mkdir -p "$(dirname "$path")"; printf '%s\n' "$@" > "$path"; }
: > "$TEMPLATE_DIR/General/Empty File"
write "$TEMPLATE_DIR/General/Text File.txt" ''
write "$TEMPLATE_DIR/General/README.md" '# Project' '' '## Description' '' '## Installation' '' '## Usage'
write "$TEMPLATE_DIR/General/Markdown.md" '# Title' ''
write "$TEMPLATE_DIR/General/JSON.json" '{' '  "key": "value"' '}'
write "$TEMPLATE_DIR/General/YAML.yml" '---' 'key: value'
write "$TEMPLATE_DIR/General/Environment.env" '# KEY=value'
write "$TEMPLATE_DIR/General/SQL.sql" '-- SQL query'
write "$TEMPLATE_DIR/Development/Shell Script.sh" '#!/usr/bin/env bash' 'set -euo pipefail' ''
write "$TEMPLATE_DIR/Development/Python Script.py" '#!/usr/bin/env python3' '' 'def main() -> None:' '    pass' '' 'if __name__ == "__main__":' '    main()'
write "$TEMPLATE_DIR/Development/Elixir Module.ex" 'defmodule ModuleName do' '  @moduledoc false' 'end'
write "$TEMPLATE_DIR/Development/Elixir Script.exs" '#!/usr/bin/env elixir' '' 'IO.puts("Hello")'
write "$TEMPLATE_DIR/Development/Phoenix Component.heex" '<div class="">' '</div>'
write "$TEMPLATE_DIR/Development/HTML Document.html" '<!doctype html>' '<html lang="en">' '<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title></title></head>' '<body></body>' '</html>'
write "$TEMPLATE_DIR/Development/Stylesheet.css" ':root {' '}'
write "$TEMPLATE_DIR/Development/JavaScript.js" '"use strict";' ''
write "$TEMPLATE_DIR/Development/TypeScript.ts" 'export {};' ''
write "$TEMPLATE_DIR/Development/Dockerfile" 'FROM alpine:latest' '' 'WORKDIR /app'
write "$TEMPLATE_DIR/Development/Compose File.yml" 'services:' '  app:' '    build: .'
write "$TEMPLATE_DIR/DoorAPI/Elixir Module.ex" 'defmodule DoorAPI.ModuleName do' '  @moduledoc false' 'end'
write "$TEMPLATE_DIR/DoorAPI/ExUnit Test.exs" 'defmodule DoorAPI.ModuleNameTest do' '  use ExUnit.Case, async: true' 'end'
write "$TEMPLATE_DIR/DoorAPI/GenServer.ex" 'defmodule DoorAPI.Worker do' '  use GenServer' '' '  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)' '  @impl true' '  def init(opts), do: {:ok, opts}' 'end'
write "$TEMPLATE_DIR/Kubernetes/Deployment.yaml" 'apiVersion: apps/v1' 'kind: Deployment' 'metadata:' '  name: app' 'spec:' '  replicas: 1' '  selector:' '    matchLabels:' '      app: app' '  template:' '    metadata:' '      labels:' '        app: app' '    spec:' '      containers:' '        - name: app' '          image: image:tag'
write "$TEMPLATE_DIR/Kubernetes/Service.yaml" 'apiVersion: v1' 'kind: Service' 'metadata:' '  name: app' 'spec:' '  selector:' '    app: app' '  ports:' '    - port: 80' '      targetPort: 4000'
write "$TEMPLATE_DIR/Kubernetes/ConfigMap.yaml" 'apiVersion: v1' 'kind: ConfigMap' 'metadata:' '  name: app-config' 'data:' '  KEY: value'
write "$TEMPLATE_DIR/Kubernetes/Secret.yaml" 'apiVersion: v1' 'kind: Secret' 'metadata:' '  name: app-secret' 'type: Opaque' 'stringData:' '  KEY: value'
find "$TEMPLATE_DIR" -type f -name '*.sh' -exec chmod 0755 {} +
touch "$TEMPLATE_DIR"; nautilus -q >/dev/null 2>&1 || true
echo "Nautilus templates installed in $TEMPLATE_DIR"
