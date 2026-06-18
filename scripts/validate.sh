#!/usr/bin/env bash
set -euo pipefail

if ! command -v yq >/dev/null 2>&1; then
  echo "missing yq" >&2
  exit 1
fi
if ! command -v ajv >/dev/null 2>&1; then
  echo "missing ajv" >&2
  exit 1
fi

tmp="$(mktemp)"
yq -o=json '.' products/registry.yml > "$tmp"
ajv validate --spec=draft2020 -s schemas/product-registry.schema.json -d "$tmp"
rm -f "$tmp"
