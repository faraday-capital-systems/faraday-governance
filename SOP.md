# Faraday Governance — Northstar & SOP

`faraday-capital-systems/faraday-governance` is the single authority for the Faraday
federation. This is how it works, how it is triggered, and the exact procedures to
operate it. Read the Northstar first; it explains why every procedure is shaped the way
it is.

Live state is tracked in [STATUS.md](./STATUS.md) (this SOP stays evergreen).

---

## 1. Northstar

**One authority, consumed by pinning, enforced fail-closed.**

- Governance holds **definitions only** — schemas, policies, gates, the product
  registry, RBAC catalog, classification labels, templates. Never instance data,
  records, evidence, engine code, or secrets. Engines and data live in product repos.
- Products **pin** an immutable governance release tag (never `main`) and **verify the
  bundle hash** at gate time. A missing or mismatched bundle **blocks** (fail-closed).
- Governance is **pull, not push.** It does not watch or reach into products. Each
  product's own CI pulls governance at its pinned tag and enforces against it. There is
  no central daemon, cron, or webhook fanning changes out.
- A change to governance does **not** auto-propagate. Products adopt a new version by
  bumping their pin — deliberately manual, so one governance edit can never silently
  alter every product at once.

If a procedure below seems to add friction (pin bumps, signed PRs, immutable tags),
that friction is the control. Do not engineer it away.

---

## 2. How governance gets triggered

There is no "run governance" action. It is triggered in exactly three ways:

| Trigger | What fires | Where |
|---|---|---|
| A **product** opens a PR | that product's `governance-validate` workflow | the product repo |
| A **governance** PR (registry/schema/policy edit) | governance's own `validate` check | faraday-governance |
| A new **release tag** `vX.Y.Z` is pushed | nothing automatic — changes the pinned contract products may adopt | faraday-governance |

### 2a. Product-side trigger (the main path)
On every product PR, `.github/workflows/governance-validate.yml` runs and:
1. reads the product's `.faraday/governance.yml` (pinned `version` + `bundle_sha256`,
   asserts `enforcement: fail_closed`);
2. `git clone --depth 1 --branch <version> <governance-repo> gov`;
3. recomputes `git -C gov archive <version> | sha256sum` and **fails closed** unless it
   equals the pinned `bundle_sha256`;
4. validates `governance.yml` against `gov/schemas/governance-ref.schema.json`;
5. drift check — finds the product in `gov/products/registry.yml` by org+repo and
   asserts pinned `version` >= the registry `governance_version`.
Any mismatch = exit non-zero = the `validate` check is red.

### 2b. Governance-side trigger
A PR to faraday-governance runs `scripts/validate.sh` via `.github/workflows/validate.yml`
(job id `validate`), which validates `products/registry.yml` against its schema. This is
the required check on `main`.

---

## 3. Pinned contract (the values everything depends on)

- Release tag: **`v1.0.0`** = `ac753335b7aac4f9ba8b79067338dab38448cd98` (immutable)
- Bundle digest: **`b086ae5d06f8e0d3211769d7efdcc66f4445b2edffa9789c0896386f421fdc5d`**
- Bundle method: `git archive <tag> | sha256sum`
- Rulesets: Protect main `17871609`, Protect v* tags `17866918` (both active)

If the digest ever changes without a new tag, **that is the system working** — hash
checks fail closed. Investigate the tag, do not loosen the check.

---

## 4. SOP — Operating procedures

### SOP-A: Onboard a new product
1. In the product repo, add `.faraday/governance.yml` pinned to the current release tag
   + its `bundle_sha256`, `enforcement: fail_closed`.
2. Bootstrap `.github/workflows/governance-validate.yml` onto the product's **default
   branch first** (a `pull_request` workflow runs from the file on BASE; a workflow
   introduced by the PR won't run on its own first PR).
3. Add `.github/CODEOWNERS` using the product's **own-org** owner/team (cross-org team
   refs do not resolve).
4. Open a governance PR adding the product to `products/registry.yml`
   (org, repo, tier, risk_class, owner, governance_version, status: `onboarding`).
5. Open the product PR; confirm `validate` is green; all commits signed/verified.
6. Merge the product PR. Then flip the registry entry `onboarding -> active`.
7. Apply product branch protection: require the `validate` check, required_signatures,
   block force-push/deletion. **Read-then-merge** — never clobber the repo's existing
   required checks; add `validate` to them.

### SOP-B: Change a governance definition (schema/policy/gate)
1. Signed branch in faraday-governance. Edit the definition.
2. Ensure `scripts/validate.sh` passes (registry still valid).
3. Open PR; `validate` must be green; commit verified.
4. Merge (self-merges on green + signature under the solo-flow concession).
5. Re-verify `v1.0.0` and the digest are **unchanged** (definition edits on `main` must
   not move the tag).
6. If the change is breaking for consumers, cut a new release tag (SOP-C). Otherwise it
   only affects `main`, which no product pins.

### SOP-C: Cut a new release
1. Confirm `main` is clean and green.
2. Tag `vX.Y.Z` (SemVer: MAJOR=breaking contract/schema, MINOR=additive, PATCH=clarify).
   Tag protection makes it immutable once pushed.
3. Compute and publish the new bundle digest: `git archive vX.Y.Z | sha256sum`.
4. Products adopt by bumping their pin (SOP-D). Nothing propagates automatically.

### SOP-D: Adopt a new governance version in a product
1. In the product, bump `.faraday/governance.yml` `version` + `bundle_sha256` to the new
   release.
2. Raise the product's `governance_version` in the registry if it's now the floor.
3. PR; `validate` re-runs against the new tag; merge when green.

### SOP-E: Registry status transitions
- `onboarding` — actively being wired up by the governing workspace.
- `active` — pinned, validated, enforced.
- `active` + `enforcement: advisory` — validate runs/reports but the repo's plan can't
  apply branch protection (cannot block). Accepted interim; re-enforce when the org
  upgrades or the repo goes public.
- `deferred` — registered placeholder, not consuming governance yet; onboarding owned by
  the product repo's own team (e.g. shield-ai). Do **not** drive from the governance
  workspace.
- `deprecated` — retired.

---

## 5. Hard rules (never violate)
- Never `--admin`-merge, force-merge, or weaken a ruleset to unblock. Solo-flow review-off
  (approval 0, last-push off, codeowner off) is a deliberate single-maintainer config, NOT
  permission to drop `required_signatures` or the `validate` check.
- Every commit to a governed repo is **signed** and goes via **PR** — including
  `advisory` repos (validate can't block them, but the discipline keeps them governed).
- Never move or recreate a release tag. Never change a published digest.
- Never put instance data, records, evidence, secrets, or engine code in governance.
- When a STOP/gate is hit, diagnose the root cause; never route around it.

---

## 6. Break-glass (emergency changes)

There is intentionally NO bypass of governance protections. If the control plane is
wedged or an emergency change is needed, the sanctioned path is to fix the root cause
through the normal signed-PR + `validate` flow — never `--admin`, never a ruleset
weakening, never a forced merge. Rationale: a control plane whose protections can be
bypassed under pressure is not a control plane. If `validate` is red for an unrelated
reason, fix that first; the gate being honest is the point. The only legitimate
"emergency" action is cutting a corrected release tag (SOP-C) and having products
adopt it (SOP-D). Any deviation from this is a deliberate decision that must be
recorded in STATUS.md with who, what, when, and how protections were restored.

---

## 7. Failure-mode runbook

**New `governance-validate` check never appears on a product's first PR.**
Cause: `pull_request` workflows run from the file on the BASE branch; a workflow
introduced BY the PR isn't on base yet.
Fix: land the workflow on the product's default branch first (its own small PR), then
re-trigger the onboarding PR.

**`validate` red on bundle-hash mismatch despite a correct pin.**
Cause: `git archive` output can vary across git versions, producing a false mismatch.
Fix: switch the bundle definition to a committed `BUNDLE.sha256` manifest. NEVER
weaken or remove the hash check.

**Solo-maintainer cannot merge: "cannot approve your own PR" / required review.**
Cause: GitHub forbids self-approval; the solo-flow concession sets approval count 0,
last-push-approval off, code-owner review off. Confirm all three are off in the
ruleset (read-modify-write the FULL object; a partial PUT silently drops rules).

**`required_signatures` blocks merge though the head commit is verified.**
Cause: the rule evaluates EVERY commit in the PR; older unsigned commits block it.
Fix: re-sign history (`git rebase --exec 'git commit --amend --no-edit -S' main`,
force-with-lease) or squash a clean signed branch. Never `--admin`.

**Branch protection / ruleset API returns 403 on a product repo.**
Cause: Free-plan private repos can't apply protection/rulesets.
Fix: decide per repo — upgrade org to Team, make repo public, or accept advisory;
record `enforcement: advisory` in the registry. Advisory still requires signed PRs.

**SSH signing fails / `unknown_key` on verification.**
Cause: agent not loaded in the shell, or the key isn't registered as a GitHub
*Signing* key (Authentication-type doesn't count).
Fix: load agent (`$HOME/.ssh/agent.sock`); register the key as type Signing
(`gh ssh-key add <pub> --type signing`); confirm with
`gh api repos/<o>/<r>/commits/<sha> --jq '.commit.verification.verified'` == true.
