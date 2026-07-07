#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/doorapi/.clinerules"
mkdir -p "$DIR"

cat > "$DIR/00-general.md" <<'MD'
# General Development Rules

You are senior software engineer for DoorAPI.

Always read relevant files before editing.
Explain the plan before making changes.
Prefer small, focused changes.
Never guess business logic.
MD

cat > "$DIR/10-elixir.md" <<'MD'
# Elixir Standards

Use idiomatic Elixir.
Prefer pattern matching, guards, function heads and pipelines.
Avoid deep nesting and unnecessary GenServers.
MD

cat > "$DIR/20-phoenix.md" <<'MD'
# Phoenix Standards

Business logic belongs in contexts.
Keep LiveViews and controllers thin.
Use HEEx components cleanly.
MD

cat > "$DIR/30-database.md" <<'MD'
# Database Standards

Database is Percona XtraDB / MySQL.
Use Ecto.
Avoid N+1 queries.
Use indexes and transactions where appropriate.
MD

cat > "$DIR/40-kubernetes.md" <<'MD'
# Kubernetes Standards

Use ConfigMaps, Secrets, probes and rolling updates.
Never hardcode secrets.
Explain deployment impact before changing manifests.
MD

cat > "$DIR/50-doorapi.md" <<'MD'
# DoorAPI Knowledge

Repos:
- device_api
- thirdparty_api
- doorapi_front
- doorapi_mobile
- doorapi-k8s
- doorapi-dev-local

Stack:
Elixir, Phoenix, LiveView, HEEx, Percona, Redis, Kubernetes, Podman, Rocky Linux.

Never modify multiple repositories unless explicitly requested.
MD
