#!/usr/bin/env bash

#==============================================================================
# CHECKSUM-PINNED HELM FOR LINUX CI
#==============================================================================

set -euo pipefail
[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]]
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location --retry 3 \
  https://get.helm.sh/helm-v3.18.4-linux-amd64.tar.gz --output "$temporary/helm.tar.gz"
printf 'f8180838c23d7c7d797b208861fecb591d9ce1690d8704ed1e4cb8e2add966c1  %s\n' "$temporary/helm.tar.gz" | sha256sum --check --status
tar -xzf "$temporary/helm.tar.gz" -C "$temporary" linux-amd64/helm
install -d "$HOME/.local/bin"
install -m 0755 "$temporary/linux-amd64/helm" "$HOME/.local/bin/helm"
if [[ -n "${GITHUB_PATH:-}" ]]; then printf '%s\n' "$HOME/.local/bin" >> "$GITHUB_PATH"; fi