# Faraday Governance

`faraday-governance` is the federated definition authority for Faraday products.
It holds versioned, machine-checkable definitions only: schemas, product registry,
security contract definitions, policy templates, gate definitions, role catalogs,
and operating templates.

This repo does not hold instance data, customer records, evidence, runtime engine
code, or secrets. Products pin released tags and verify the bundle digest before
using these definitions.
