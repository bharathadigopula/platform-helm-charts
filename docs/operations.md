# Ownership and Release Operations

Repository owner: `bharathadigopula`. Public product/platform brand: BharathCoudOps.

## Ownership Boundaries

This repository owns generic Kubernetes workload templates and their security contract. Application repositories own business logic, database migrations, environment values and release image digests. Host configuration and infrastructure repositories own OCI VMs, network access, Cloudflare routes and Vault resources. Jenkins owns approved production execution. None of those production resources is created merely by publishing this chart.

Do not copy private app source, OCI secret payloads, account passwords, patient data, live kubeconfigs or production host inventories here. Operational inventories belong in the private application repository's documentation. Name credentials there without recording their values.

## Release Gates

1. Change chart code with matching tests and values documentation.
2. Increment Chart.yaml version using semantic versioning.
3. Pass Helm rendering, schema/negative tests and shared shell validation in a pull request.
4. Test the release in an isolated local Kubernetes cluster using an explicit dedicated kubeconfig. Never use a company/default cluster.
5. Merge through required repository checks. Release only the tested commit.
6. Package with `helm package charts/web-service --destination dist`, generate a SHA-256 checksum, and publish the versioned package with the source commit in the release notes.
7. Consumers pin the release's exact commit/package checksum. Protect release tags against modification or deletion.

## Migration Order

Provision a dedicated namespace and restricted secret delivery first. Install database with application replicas zero and ingress disabled. Restore a verified, encrypted backup, including stable auth and integration-encryption keys. Run the explicit migration Job and wait for completion. Enable the app, check readiness and SMTP, test a restored backup, then enable ingress and switch the upstream route. Prevent concurrent writes to old and new databases during cutover.

Helm rollback restores workload configuration, not database contents. Retain the source database and old runtime configuration until post-cutover checks pass. Any rollback after new writes requires reconciliation; never silently switch back to a stale database. Backups, recovery credentials, retention and restore drills must be implemented by the consuming application before claiming production readiness.

## Current Validation Scope

Offline chart tests verify rendering, safe defaults and rejected inputs. A separate disposable Kind job tests non-root application/PostgreSQL readiness, a no-op migration container and PVC retention. It does not establish application-specific migration compatibility, CNI enforcement, production node capacity, provider approvals or end-to-end application readiness. Those remain deployment gates, not chart claims.