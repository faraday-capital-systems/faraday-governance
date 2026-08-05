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

tmp="$(mktemp --suffix=.json)"
trap 'rm -f "$tmp" "${tmp%.json}-review-policy.json"' EXIT
yq -o=json '.' products/registry.yml > "$tmp"
ajv validate --spec=draft2020 -s schemas/product-registry.schema.json -d "$tmp"

# Faraday Review policy bundle: assemble the four YAMLs into one object
# keyed by file basename and validate against the bundle schema.
bundle_tmp="${tmp%.json}-review-policy.json"
yq -o=json -n '
  {"approval-policy": load("review-policy/approval-policy.yaml"),
   "protected-paths": load("review-policy/protected-paths.yaml"),
   "evidence-requirements": load("review-policy/evidence-requirements.yaml"),
   "provider-requirements": load("review-policy/provider-requirements.yaml")}
' > "$bundle_tmp"
ajv validate --spec=draft2020 -s review-policy/policy.schema.json -d "$bundle_tmp"
