# Kubernetes Standards

Deployment target:

Kubernetes

Use:

- ConfigMaps
- Secrets
- Readiness probes
- Liveness probes

Never hardcode:

- passwords
- api keys
- tokens

Container images:

Keep small.

Use health checks.

Always explain deployment impact before changing manifests.

Prefer rolling updates.
