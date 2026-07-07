# DoorAPI Project Knowledge

Workspace repositories:

- device_api
- thirdparty_api
- doorapi_front
- doorapi_mobile
- doorapi-k8s
- doorapi-dev-local

Backend:

Elixir 1.18

Phoenix

LiveView

HEEx

Redis

Percona

Infrastructure:

Podman

Kubernetes

Cockpit

Rocky Linux

Coding philosophy:

Production first.

Maintain backwards compatibility.

Avoid unnecessary dependencies.

Prefer existing project conventions over introducing new frameworks.

Never modify multiple repositories unless explicitly requested.

When changing APIs:

Consider impact on:

- Frontend
- Mobile
- Third-party API
- Kubernetes deployment

Always think about:

Authentication

Authorization

Performance

Scalability

Maintainability
