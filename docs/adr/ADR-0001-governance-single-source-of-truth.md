# ADR-0001: Governance Single Source of Truth

- **Status:** Proposed — awaiting owner ratification
- **Date:** 2026-07-02
- **Deciders:** platform owner, shield-ai owner, faraday-governance owner
- **Source:** ecosystem audit — `ecosystem-inventory/_governance-ssot.md` (read-only discovery, VERIFIED facts)

## Context (VERIFIED)

Two repos claim governance authority at different layers:

- **faraday-governance** — federated policy *definitions*; SOP declares "single authority"; actively serves versioned definitions to PSE, orbit-console, and founder-pm via pin+hash.
- **shield-ai** — OPA policy *runtime*, self-described "sovereign governance brain"; 5 rego policies (1 implemented, 4 stub) + PolicyBundle machinery.

They are **not integrated**: shield-ai does not load faraday-governance definitions (no pin, no `.faraday/governance.yml`, no reference); its registry status is `deferred`, with onboarding owned by the shield-ai repo.

Drift is **already occurring**: `audit-event.schema.json` exists in both repos with different `$id` and size.

shield-lite is an edge kiosk/command-node UI (Phase 0), **not** the governance edge agent (future `shield-edge`, per shield-ai ADR-0002). faraday-security is a placeholder. Neither is a governance authority.

## Decision

1. **faraday-governance is the definitions SSOT.** All *deployed* policy definitions and shared governance schemas (including `audit-event.schema.json`) are versioned in and served from faraday-governance via the existing pin+hash mechanism.
2. **shield-ai is the governance runtime.** It evaluates policy via OPA; it holds no independent authority over policy definitions. Charter/README corrected from "sovereign governance brain" to "governance policy runtime that enforces faraday-governance-authored PolicyBundles."
3. **Policies flow through governance.** shield-ai's rego is registered as faraday-governance PolicyBundles and consumed by shield-ai via pin+hash — the same path already serving PSE/orbit/founder-pm. shield-ai may author/propose rego for velocity, but governance owns the released, versioned bundle (publish gate).
4. **Onboarding implements this ADR.** shield-ai registry status moves `deferred` → `active` when consumption is wired.
5. **Schema dedup.** faraday-governance's `audit-event.schema.json` is authoritative; shield-ai deletes its divergent copy and consumes the governance version.

## Out of scope

- shield-lite (edge UI) and faraday-security (placeholder) — not governance authorities.
- shield-ai internal bugs, routed to shield-ai owner and tracked separately:
  - (a) rego query-path mismatch — `data.shield.decision` string vs `default-deny.rego` object
  - (b) README says "scaffold only" while `shield serve` + decision/audit/intake are implemented

## Consequences

**Positive:** one deployed-policy authority; the live `audit-event.schema` divergence is resolved; shield-ai's `deferred` status gets a defined path to `active`; new/siloed repos align to a single definitions source.

**Cost / risk:** shield-ai's implemented rego must migrate to a governance bundle — one-time, Medium effort. A publish/pin step is added to policy release (mitigated by allowing shield-ai to author + propose).

**Follow-up (separate decision):** faraday-governance currently sits under the **faraday-capital-systems** org. As an ecosystem-wide SSOT it is mislocated inside a single vertical's org; recommend relocating to the **faraday-platform (Foundation)** org. In-repo placement rationale was UNKNOWN in discovery.

## Alignment role

This ADR is **Fixed Point #1** of the ecosystem alignment scaffold: siloed repos consume governance definitions via pin+hash rather than authoring their own. The pre-existing `audit-event.schema` divergence is the canonical drift this control prevents — the recurring coupling scan should fail any repo shipping a governance schema not sourced from faraday-governance.
