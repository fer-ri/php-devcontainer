#!/usr/bin/env bash
set -euo pipefail

PUSH=false
SHOW_HELP() { echo "Usage: $0 [--push]"; echo "  --push   Push images to GHCR after building (CI uses this)."; echo "  Without --push only builds locally (safe for testing)."; exit 0; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=true ;;
    --help|-h) SHOW_HELP ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

REGISTRY="ghcr.io/fer-ri"
IMAGE="php-devcontainer"

PHP_VERSIONS=("7.4" "8.5")
TARGETS=("base" "dev" "ci")

# Node source image per PHP version (must match the Alpine base of each
# serversideup PHP image to avoid libstdc++ mismatches when COPY-ing node).
node_image_for() {
  case "$1" in
    7.4) echo "node:18-alpine3.16" ;;
    *)   echo "node:24-alpine" ;;
  esac
}

for php in "${PHP_VERSIONS[@]}"; do
  NODE_IMAGE="$(node_image_for "$php")"
  for target in "${TARGETS[@]}"; do
    tag="${REGISTRY}/${IMAGE}:${php}-${target}"
    echo ">> Building ${tag} (node: ${NODE_IMAGE})"
    docker build \
      --build-arg "PHP_VERSION=${php}" \
      --build-arg "NODE_IMAGE=${NODE_IMAGE}" \
      --target "${target}" \
      --tag "${tag}" \
      -f Dockerfile .

    if $PUSH; then
      docker push "${tag}"
    else
      echo "   (skipped push, pass --push to push)"
    fi
  done
done

$PUSH || echo ">> Dry-run complete. Re-run with --push to publish to ${REGISTRY}/${IMAGE}."
