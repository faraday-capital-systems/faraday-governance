# Faraday Governance Roadmap

Status: recorded for reopen, not active implementation  
Branch: `governance-live-hardening-roadmap`  
Scope owner: `faraday-capital-systems/faraday-governance`  
Last updated: 2026-06-24

---

## 1. Current State

`faraday-governance` is operational today for product governance.

It is already the federated definition authority for Faraday product governance and currently supports the live product-governance path:

- products pin an immutable governance release tag;
- products verify the pinned governance bundle;
- product PRs run `governance-validate`;
- validation fails closed on mismatch or drift;
- governed repos record evidence in their product-side evidence path;
- governance itself remains definitions-only.

This repo is not merely a scaffold. It is a live product-governance control plane.

The next capability tier is to extend the same control-plane model from product contracts to model-brain contracts. That is an expansion of scope, not a prerequisite for the existing product-governance system.

---

## 2. Locked Boundary

`faraday-governance` defines contracts. It does not execute governance.

Runtime engines, runtime decisions, evidence instances, customer data, secrets, and product records remain outside this repository.

Correct boundary:

```text
faraday-governance = definitions, schemas, policies, registries, templates, contracts
shield-ai          = evaluation authority / runtime decision engine
orbit              = orchestration and enforcement surface
product repos      = implementation and product-side evidence
faraday-vault      = knowledge-system support layer, not governance runtime
```

Shield onboarding is not driven from this repository.

Governance's responsibility is to prepare the contracts Shield will eventually consume. The `shield-ai` repository owns its own readiness, onboarding, and consumption of governance.

---

## 3. Immediate Hardening Item

### Replace `git archive | sha256sum` with committed `BUNDLE.sha256`

Current live verification uses:

```bash
git archive <tag> | sha256sum
```

This is fragile because archive output can differ across Git versions or archive implementations even when file contents are unchanged. Since products fail closed, a runner/tooling difference could create a false fleet-wide mismatch.

The replacement is a committed manifest:

```text
BUNDLE.sha256
```

This manifest should be generated deterministically at release time, committed into the tagged tree, and used by products for verification.

---

## 4. BUNDLE.sha256 Design

### 4.1 Release-time generation

At release time, before tagging:

1. Select the tracked governance definition files using one canonical file-selection rule.
2. Sort selected file paths deterministically.
3. Compute `sha256` over each selected file's content.
4. Write the ordered file-hash manifest to `BUNDLE.sha256`.
5. Commit `BUNDLE.sha256`.
6. Tag the release only after the manifest commit is included.

The release tag must contain the manifest file.

Example manifest shape:

```text
<sha256>  products/registry.yml
<sha256>  schemas/governance-ref.schema.json
<sha256>  schemas/product-registry.schema.json
<sha256>  schemas/audit-event.schema.json
<sha256>  roles/catalog.yml
<sha256>  classification/labels.yml
```

The product still pins one digest value in `.faraday/governance.yml`:

```yaml
governance:
  version: vX.Y.Z
  bundle_sha256: <sha256-of-BUNDLE.sha256-file>
```

The pinned `bundle_sha256` is the hash of the manifest file itself, not the hash of a Git archive.

This preserves a single pinned value while allowing the manifest to expand into deterministic per-file verification.

---

### 4.2 Product verification flow

Product-side `governance-validate` should change from archive verification to manifest verification.

New verification flow:

1. Read `.faraday/governance.yml`.
2. Clone `faraday-governance` at the pinned tag.
3. Assert `BUNDLE.sha256` exists in the cloned tag.
4. Compute `sha256sum BUNDLE.sha256`.
5. Compare that value to the product's pinned `bundle_sha256`.
6. Recompute the per-file manifest using the exact same file-selection rule.
7. Compare the recomputed manifest to the committed `BUNDLE.sha256`.
8. Fail closed on any mismatch.

Failure behavior:

```text
tampered definition file
  -> recomputed manifest differs from committed BUNDLE.sha256
  -> block

tampered manifest
  -> sha256(BUNDLE.sha256) differs from pinned bundle_sha256
  -> block

missing manifest
  -> block

file-selection mismatch
  -> block
```

---

### 4.3 Canonical file-selection rule

The generator and verifier must use the same file-selection rule.

This rule should live in one canonical script or manifest config, not be duplicated manually across repos.

The selected files must include definition artifacts only, such as:

```text
agent-standards/**
classification*/**
constitutional/**
contracts/**
gates/**
policies/**
products/**
promotion-gates/**
roles/**
schemas/**
shield-policies/**
templates/**
VERSIONING.md
SOP.md
README.md
```

The selected files must exclude variable or runtime artifacts, such as:

```text
.git/**
.github/workflow run outputs
node_modules/**
coverage/**
logs/**
.env*
secrets
runtime evidence
customer data
instance data
product-side records
```

The precise rule should be implemented as code during reopen, but the design requirement is fixed:

```text
One canonical file-selection rule.
Stable ordering.
File-content hashing only.
No archive framing.
No runtime or generated noise.
```

---

## 5. Versioning Decision

Switching bundle verification changes the contract between governance and product repos.

There are two acceptable release paths.

### Option A — MINOR additive transition

Use a minor release if both methods are temporarily supported:

```text
v1.1.0
```

Rules:

- Old products may continue using archive-hash verification during transition.
- New/adopting products use manifest verification.
- Governance schema may accept a `bundle_method` field or equivalent migration marker.
- Product adoption happens intentionally via SOP-D.

Recommended if the goal is low-disruption migration.

### Option B — MAJOR hard cut

Use a major release if archive verification is removed immediately:

```text
v2.0.0
```

Rules:

- Products must update their verifier before pinning the new release.
- The governance reference contract changes from archive digest to manifest digest.
- Any product still using archive verification must remain pinned to the old release.

Recommended only if the platform wants a clean break and coordinated product updates.

### Open decision

Do not implement until this is decided at reopen:

```text
Decision needed: v1.1.0 additive dual-method transition or v2.0.0 hard-cut migration.
```

Default recommendation:

```text
Use v1.1.0 with dual-method support during transition.
```

Reason:

- preserves current product governance;
- avoids forcing simultaneous product-repo updates;
- keeps fail-closed semantics;
- allows each product to adopt the manifest method deliberately through SOP-D.

---

## 6. Phase 1 Queue — Brain Contract Definition Tier

This is queued scope only. Do not start until the project is reopened.

The goal is to extend governance from product contracts to model-brain contracts.

This work belongs in `faraday-governance` only as definitions, schemas, policies, and templates.

Queued artifacts:

```text
schemas/brain-contract.schema.json
schemas/agent-contract.schema.json
schemas/tool-contract.schema.json
schemas/decision.schema.json
schemas/evidence.schema.json
schemas/policy-bundle.schema.json
constitutional/authority-boundaries.yml
constitutional/forbidden-actions.yml
constitutional/break-glass-policy.yml
constitutional/faraday-constitution.yml
```

Potential registry:

```text
brains/registry.yml
```

Caution:

A brain registry is an intentional instance-ish exception, similar to the product registry. It is defensible only if it is required as the enforcement denominator for federation governance.

Governance may define:

```text
what brain contracts look like
what decisions must look like
what tools may be declared
what authority boundaries exist
what actions are forbidden
what evidence shape is required
```

Governance must not store:

```text
actual Shield decisions
runtime prompts
runtime model outputs
customer evidence
approval records
secrets
product execution data
```

---

## 7. Phase 2 — Shield-Owned Consumption

Shield is the evaluation authority, but Shield onboarding is not driven by this repository.

Governance-side responsibility:

```text
prepare and publish the contracts
```

Shield-side responsibility:

```text
consume the contracts when shield-ai is ready
emit valid decision instances elsewhere
validate policy bundles at runtime
write runtime evidence outside governance
```

Do not move Shield from `deferred` to `onboarding` or `active` from the governance workspace alone.

That transition is owned by the `shield-ai` repo.

---

## 8. Later Phases

### Governance health dashboard

Queued but unchanged.

Dashboard should eventually surface:

```text
product
governance version
bundle method
bundle digest match
enforcement mode
last validation status
branch protection status
signed commit status
risk class
evidence path health
Shield consumption status
policy drift
```

### Global governance standard

Once products and model brains consume governance through pinned releases, this repo becomes the Faraday Global Governance Contract Registry.

Target state:

```text
products pin governance
model brains consume governance contracts
Shield evaluates against governance definitions
Orbit routes and enforces through approved surfaces
product repos store implementation and evidence
no runtime authority lives in governance
```

---

## 9. Close-Out Rule

This roadmap records the next work without starting it.

Allowed before reopen:

```text
documentation only
no generator code
no verifier code
no product-repo changes
no Shield onboarding
no release tag
```

Implementation begins only when the governance project is reopened and the versioning decision is made.
