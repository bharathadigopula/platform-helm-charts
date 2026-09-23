#!/usr/bin/env bash

#==============================================================================
# CHECKSUM-PINNED HELM FOR LINUX CI
#==============================================================================

set -euo pipefail

#==============================================================================
# PLATFORM GUARD AND TEMPORARY DOWNLOAD LIFECYCLE
#==============================================================================
[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]]
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT

#==============================================================================
# VERIFIED HELM ARCHIVE DOWNLOAD
#==============================================================================
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location --retry 3 \
  https://get.helm.sh/helm-v3.18.4-linux-amd64.tar.gz --output "$temporary/helm.tar.gz"
printf 'f8180838c23d7c7d797b208861fecb591d9ce1690d8704ed1e4cb8e2add966c1  %s\n' "$temporary/helm.tar.gz" | sha256sum --check --status

#==============================================================================
# USER-SCOPED INSTALLATION AND GITHUB ACTIONS PATH
#==============================================================================
tar -xzf "$temporary/helm.tar.gz" -C "$temporary" linux-amd64/helm
install -d "$HOME/.local/bin"
install -m 0755 "$temporary/linux-amd64/helm" "$HOME/.local/bin/helm"

#==============================================================================
# CHECKSUM-PINNED KIND FOR DISPOSABLE CI CLUSTERS
#==============================================================================
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location --retry 3 \
  https://github.com/kubernetes-sigs/kind/releases/download/v0.32.0/kind-linux-amd64 --output "$temporary/kind"
printf '50030de23cf40a18505f20426f6a8506bedf13c6e509244bd1fa9463721b0f54  %s\n' "$temporary/kind" | sha256sum --check --status
install -m 0755 "$temporary/kind" "$HOME/.local/bin/kind"

#==============================================================================
# EXPOSE ONLY USER-SCOPED TOOLS TO FOLLOWING CI STEPS
#==============================================================================
if [[ -n "${GITHUB_PATH:-}" ]]; then printf '%s\n' "$HOME/.local/bin" >> "$GITHUB_PATH"; fi