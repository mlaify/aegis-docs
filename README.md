# aegis-docs

Public-facing documentation for the Aegis system.

`aegis-docs` explains how to understand, run, and contribute to Aegis.
It is intentionally complementary to `aegis-spec`.

## Role of `aegis-docs`

This repo is for:

- tutorials and getting-started guides
- developer setup and local workflow guidance
- architecture explanations for contributors
- security model summaries for humans
- repository map and onboarding material
- operational runbooks (as they are added)

This repo is NOT the normative protocol source of truth.

## Relationship to `aegis-spec`

Use `aegis-spec` for normative protocol artifacts:

- RFCs
- JSON schemas
- implementation conformance matrix
- protocol change policy

Use `aegis-docs` to explain and navigate those artifacts.

## Documentation Structure

- `docs/getting-started.md`
- `docs/architecture-overview.md`
- `docs/local-development.md`
- `docs/security-model.md`
- `docs/repository-map.md`

Legacy top-level docs currently remain:

- `architecture.md`
- `threat-model.md`
- `philosophy.md`

They are being retained for compatibility while the `docs/` structure is established.

## Current v0.1.0-alpha Status Caveats

Aegis `v0.1.0-alpha` is in draft/prototype stage.

- no production post-quantum cryptography yet
- no production resolver service yet
- relay/gateway/client production maturity is still in progress

## Contribution Rules

- Keep `aegis-spec` as normative truth for protocol details.
- Summarize and link RFCs instead of duplicating full RFC text.
- For protocol behavior changes, update `aegis-spec` first and then align docs here.

See `CONTRIBUTING.md` for workflow details.

Additional project-level notes:

- `docs/v0.1.0-alpha-checklist.md`
- `docs/versioning-policy.md`
