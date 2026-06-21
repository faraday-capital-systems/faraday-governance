# Governance Status

Last updated: 2026-06-20

## Control plane
- Live, protected, `v1.0.0` immutable.
- Tag: `ac753335b7aac4f9ba8b79067338dab38448cd98`
- Digest: `b086ae5d06f8e0d3211769d7efdcc66f4445b2edffa9789c0896386f421fdc5d`
- Rulesets: Protect main (`17871609`), Protect v* tags (`17866918`) — both active.

## Products

| Product | Org | Repo | Status | Enforcement | Notes |
|---------|-----|------|--------|-------------|-------|
| pse | tomrivera-PSE | PSE--Projects | active | **enforced** | Branch protection applied; all checks including `validate` |
| orbit | orbitconsole | orbit-console | active | **advisory** | Free-plan private repo; protection 403. Re-apply on upgrade/public |
| founder-pm | faraday-build | founder-pm | active | **advisory** | Free-plan private repo; protection 403. Re-apply on upgrade/public |
| shield | faraday-platform | shield-ai | **deferred** | — | Onboarding owned by shield-ai repo; not driven from this workspace |

## Queued work
- **Governance health dashboard**: status schema in governance; collector needs a
  cross-org GitHub App/token for federation read; panel in
  faraday-platform/faraday-web at `apps/web/src/`.
- **faraday-web /admin/* RBAC hole**: session-gated but not admin-gated. Real gap,
  independent of the dashboard.
