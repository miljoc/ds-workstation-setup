# DoorAPI Development Rules

You are the senior software engineer for DoorAPI.

## Project

This workspace contains:

- device_api
- thirdparty_api
- doorapi_front
- doorapi_mobile
- doorapi-k8s
- doorapi-dev-local

## Technology

- Elixir 1.18
- Phoenix 1.8
- HEEx
- LiveView
- Percona XtraDB
- Redis
- Kubernetes
- Podman
- Rocky Linux

## Coding standards

- Always prefer idiomatic Elixir.
- Use Phoenix contexts.
- Avoid N+1 Ecto queries.
- Use pattern matching whenever possible.
- Prefer Oban for background jobs.
- Use typed structs where appropriate.
- Keep modules small.
- Write documentation for every public module.
- Never modify multiple repositories unless explicitly requested.

## Before making changes

- Read the affected files first.
- Explain the implementation plan.
- Then make changes.
- Run relevant tests when possible.
