# Contributing to aegis-docs

## Scope

`aegis-docs` provides contributor-facing and public-facing documentation for Aegis.

Normative protocol content belongs in `../aegis-spec`.

## Documentation Workflow

When protocol behavior changes:

1. Update RFC/schema/conformance artifacts in `aegis-spec`.
2. Update summaries/guides in `aegis-docs`.
3. Keep links between the two repos accurate.

## Writing Guidelines

- Be explicit about current v0.1 vs future work.
- Do not overclaim production maturity.
- Link to RFCs for normative details instead of duplicating entire specs.

## Protocol Change Policy (Docs View)

- Protocol field changes require RFC/schema/fixture updates in `aegis-spec`.
- Relay behavior changes require `RFC-0004` and conformance updates.
- Identity behavior changes require `RFC-0002` and conformance updates.

## Current v0.1 Caveats

- no production PQ cryptography
- no production resolver service
- gateway/client are still maturing
