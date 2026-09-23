#!/usr/bin/env bash

#==============================================================================
# DISPOSABLE LOCAL KIND SMOKE TEST - NO DEFAULT KUBECONFIG ACCESS
#==============================================================================

set -euo pipefail

#==============================================================================
# ISOLATED CLUSTER NAME AND KUBECONFIG
#==============================================================================
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temporary=$(mktemp -d)
cluster="helm-smoke-$$"
kubeconfig="$temporary/kubeconfig"
created=false

#==============================================================================
# CLEAN UP ONLY THE DISPOSABLE TEST CLUSTER
#==============================================================================
cleanup() {
  if [[ "$created" == true ]]; then kind delete cluster --name "$cluster" --kubeconfig "$kubeconfig"; fi
  rm -rf "$temporary"
}
trap cleanup EXIT

#==============================================================================
# PINNED LOCAL CLUSTER AND RESTRICTED POD SECURITY
#==============================================================================
kind create cluster --name "$cluster" --kubeconfig "$kubeconfig" \
  --image docker.io/kindest/node:v1.35.0@sha256:4613778f3cfcd10e615029370f5786704559103cf27bef934597ba562b269661 --wait 180s
created=true
kubectl_command=(kubectl --kubeconfig "$kubeconfig" --context "kind-$cluster")
[[ "$("${kubectl_command[@]}" config current-context)" == "kind-$cluster" ]]
"${kubectl_command[@]}" create namespace example
"${kubectl_command[@]}" label namespace example pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=v1.35

#==============================================================================
# EPHEMERAL TEST CREDENTIALS - NEVER PRINTED OR PERSISTED IN GIT
#==============================================================================
password=$(openssl rand -hex 24)
"${kubectl_command[@]}" -n example create secret generic example-database --from-literal="POSTGRES_PASSWORD=$password"
"${kubectl_command[@]}" -n example create secret generic example-runtime --from-literal="DATABASE_URL=postgresql://app:$password@example-postgres:5432/app"
unset password

#==============================================================================
# IMMUTABLE PUBLIC TEST IMAGES AND EXPLICIT RELEASE SETTINGS
#==============================================================================
helm_arguments=(--kubeconfig "$kubeconfig" --kube-context "kind-$cluster" --namespace example
  --set-string image=docker.io/nginxinc/nginx-unprivileged@sha256:4714e0b1b2577eaa1a6131d07c958b67f0eb68e6d0521e90c6e5287db8cf0bc5
  --set-string runtimeSecret=example-runtime --set 'runAsUser=101,runAsGroup=101,port=8080,replicas=1'
  --set-string readinessPath=/ --set 'database.enabled=true,database.storage=1Gi,database.storageClass=standard'
  --set-string database.image=docker.io/library/postgres@sha256:721873c34ceb9f8d8fc265984940dc982404c105f19ad51be9fdc5970a6080ea
  --set-string database.existingSecret=example-database --set migration.enabled=true
  --set-string migration.image=docker.io/library/bash@sha256:61962062d969cb46dfc2bad061d36342406fa485f64f246aa7e95693ca07df1f)

#==============================================================================
# WAIT FOR ALL WORKLOADS; REPORT NON-SECRET FAILURE DIAGNOSTICS
#==============================================================================
if ! helm upgrade --install example "$root/charts/web-service" "${helm_arguments[@]}" --wait --wait-for-jobs --timeout 8m; then
  "${kubectl_command[@]}" -n example get pods
  "${kubectl_command[@]}" -n example get events --field-selector type=Warning
  exit 1
fi

#==============================================================================
# DATABASE, HTTP AND MIGRATION COMPLETION CHECKS
#==============================================================================
"${kubectl_command[@]}" -n example exec example-postgres-0 -- psql -U app -d app -tAc 'SELECT 1' | grep -qx 1
"${kubectl_command[@]}" -n example exec deployment/example -- wget -qO- http://127.0.0.1:8080/ | grep -q 'Welcome to nginx'
"${kubectl_command[@]}" -n example wait --for=condition=complete job/example-migrate-1 --timeout=30s

#==============================================================================
# UNINSTALL MUST RETAIN THE DATABASE CLAIM
#==============================================================================
helm uninstall example --kubeconfig "$kubeconfig" --kube-context "kind-$cluster" --namespace example --wait --timeout 2m
"${kubectl_command[@]}" -n example get pvc pgdata-example-postgres-0 -o jsonpath='{.status.phase}' | grep -qx Bound
printf 'isolated_chart_runtime=ready\n'