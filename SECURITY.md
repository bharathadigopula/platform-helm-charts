# Security Policy

Report vulnerabilities through this repository's private vulnerability reporting feature. Do not publish credentials, kubeconfigs, production logs, customer data or exploit details in public issues.

Security fixes target the latest tagged chart version. Pin consumers to an immutable commit or a versioned package plus its verified checksum; never consume a moving branch in production.

## Security Boundaries

- Public repository: generic templates, synthetic fixtures and operating instructions only.
- Application repositories: environment configuration and version pins.
- OCI Vault and namespaced Kubernetes Secrets: credentials. The chart only references existing Secrets and does not accept inline secret values.
- CI: offline rendering and validation, read-only GitHub permissions, no kubeconfig or production credentials.
- Jenkins: approved production operations using an explicit personal OCI target and kubeconfig. Never use an operator's default Kubernetes context.
- Pods: non-root, read-only root filesystem, dropped capabilities, RuntimeDefault seccomp and no mounted service-account token.
- Networking: release-scoped default deny; explicitly selected ingress controller and DNS, private PostgreSQL and public HTTPS/SMTP only by default. A network-policy-enforcing CNI is required. Policies are additive; another broad policy can weaken isolation.

## Limitations

This chart is not a security certification or a complete SaaS platform. Local-path volumes do not provide high availability or off-host backups. The consumer must supply encrypted backups, restore tests, secret rotation, monitoring, TLS termination and a rollback procedure. Database credentials remain in Kubernetes Secrets; cluster encryption at rest and RBAC are operator responsibilities. An ingress without `tlsSecret` requires an independently secured private edge connector. Never expose the origin publicly without access controls.

Migration Jobs are explicit, not automatic hooks. The deployment pipeline must wait for successful migration before starting the application. Schema rollback is not implied by Helm rollback.

## Repository Controls

The maintainer configures required pull requests, passing CI, stale-review dismissal, resolved review conversations, linear history and denial of force pushes/deletion on main. Secret scanning, push protection, vulnerability alerts and private reporting must remain enabled where GitHub supports them. A personal one-maintainer repo does not provide independent human review; add another trusted reviewer before requiring a second-person approval.