# BharathCoudOps Platform Helm Charts

Reusable Helm charts maintained by `bharathadigopula`. Production deployment is performed by Jenkins; GitHub Actions only validates repository changes.

## Contents

| Path | Purpose |
|---|---|
| `charts/web-service` | Web application, optional PostgreSQL, explicit migration Job, ingress and network policies |
| `scripts` | Versioned offline validation and checksum-pinned CI tooling |
| `.github` | Validation, ownership and dependency updates |
| `docs` | Architecture, release and operational boundaries |

## Validation

```sh
bash scripts/validate.sh
shellcheck scripts/*.sh
```

Helm 3.18.4 is the pinned CI version. Validation does not contact a cluster. Render tests are not a substitute for an isolated-cluster deployment test.

## Consumer Configuration

Consumers check out a released version at its exact commit and keep environment values in their own repository. Create the namespace and the referenced Secrets through the approved secret-delivery workflow before installing. Use a dedicated kubeconfig explicitly for every production operation.

The image digests below are placeholders, not runnable images:

```yaml
image: example.invalid/app@sha256:0000000000000000000000000000000000000000000000000000000000000000
runtimeSecret: app-runtime
registrySecret: app-registry
replicas: 0
port: 3100
readinessPath: /api/health/ready
database:
  enabled: true
  image: postgres@sha256:0000000000000000000000000000000000000000000000000000000000000000
  existingSecret: app-database
  name: app
  username: app
  storageClass: local-path
  storage: 8Gi
migration:
  enabled: false
  image: example.invalid/migrate@sha256:0000000000000000000000000000000000000000000000000000000000000000
ingress:
  enabled: false
  className: traefik
  hostname: app.example.invalid
```

Validate privately held values with `helm template example charts/web-service --namespace example --values /path/to/private-values.yaml`. Do not put credential values in Helm values, command-line `--set`, rendered manifests, GitHub artifacts or logs.

## Values Reference

| Key | Default | Description |
|---|---|---|
| `image` | empty, required | Runtime image including sha256 digest |
| `replicas` | `0` | Explicitly enable after restore/migration verification; 0-10 |
| `port` | `3100` | Unprivileged application/service port |
| `runtimeSecret` | empty, required | Existing same-namespace Secret containing application environment |
| `registrySecret` | empty | Optional existing registry pull Secret |
| `runAsUser`, `runAsGroup` | `1001` | Non-root app and migration identity |
| `readinessPath` | `/api/health/ready` | Startup/readiness HTTP endpoint; liveness uses TCP |
| `resources.requests` | `100m`, `256Mi` | App CPU/memory requests |
| `resources.limits` | `1`, `1Gi` | App CPU/memory limits |
| `migration.enabled` | `false` | Create revision-named migration Job; pipeline waits explicitly |
| `migration.image` | empty | Required immutable image when enabled; image CMD runs migration |
| `migration.databaseUrlKey` | `DATABASE_URL` | Runtime Secret key injected as DATABASE_URL |
| `database.enabled` | `false` | Create private PostgreSQL StatefulSet and headless Service |
| `database.image` | empty | Required immutable PostgreSQL image when enabled |
| `database.existingSecret` | empty | Existing Secret containing POSTGRES_PASSWORD; do not override POSTGRES_DB/USER there |
| `database.storageClass`, `database.storage` | `local-path`, `8Gi` | Persistent claim class/capacity; local-path does not support resizing |
| `database.runAsUser`, `database.runAsGroup` | `70`, `70` | PostgreSQL Alpine identity; match the chosen image |
| `database.name`, `database.username` | `app`, `app` | Initial database and role; runtime DATABASE_URL must match |
| `database.resources.requests` | `100m`, `256Mi` | PostgreSQL CPU/memory requests |
| `database.resources.limits` | `1`, `512Mi` | PostgreSQL CPU/memory limits |
| `ingress.enabled` | `false` | Opt-in host routing |
| `ingress.className`, `ingress.hostname` | `traefik`, empty | Controller class and required hostname when enabled |
| `ingress.tlsSecret` | empty | Existing TLS Secret; otherwise secured edge termination required |
| `networkPolicy.enabled` | `true`, required | Cannot be disabled through values |
| `networkPolicy.ingressNamespace` | `kube-system` | Namespace of the allowed ingress controller |
| `networkPolicy.ingressPodLabels` | `app.kubernetes.io/name: traefik` | Allowed controller pod selector |
| `networkPolicy.publicEgressPorts` | `[443, 587]` | Public TCP destinations; excludes private, loopback and link-local ranges |

The database hostname is `<release>-postgres`. PVCs survive StatefulSet deletion, but deleting the namespace can delete data. Deployment uses Recreate for constrained single-node hosts, so upgrades may interrupt traffic. Migration pods request 100m/256Mi and are limited to 1 CPU/512Mi with a ten-minute deadline. Temporary pod storage is capped at 64Mi; PostgreSQL runtime socket storage is 16Mi. No automatic database major-version upgrade is provided.

See [operations](docs/operations.md) and [security](SECURITY.md) before production use.