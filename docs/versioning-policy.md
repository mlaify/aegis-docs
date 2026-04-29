# Versioning Policy

Aegis currently uses a multi-repo `v0.1.0-alpha` milestone convention.

## Current Policy

- `v0.1.0-alpha` indicates draft/prototype status.
- Protocol norms are versioned in `aegis-spec` RFCs and schemas.
- Behavior marked `partial` or `future` in conformance is not production-complete.
- Tag naming convention is documented in `release-runbook.md`.

## Change Expectations

- Protocol field changes require RFC + schema + fixture updates.
- Behavior changes in relay/identity/crypto boundaries require conformance updates.
- Human-facing docs in `aegis-docs` summarize but do not redefine normative behavior.
