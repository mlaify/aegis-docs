# Repository Map

Aegis is developed across multiple repositories.

## Protocol-Normative Repo

- `aegis-spec`
  - RFCs
  - JSON schemas
  - conformance matrix
  - protocol change policy

## Implementation Repos

- `aegis-core` - shared Rust crates
- `aegit-cli` - local operator/developer CLI
- `aegis-relay` - reference relay
- `aegis-sdk` - thin developer SDK wrappers

## Documentation Repo

- `aegis-docs` (this repo)
  - guides, tutorials, onboarding, architecture summaries

## Gateway/Client Context

- `aegis-gateway` and `aegis-client` exist, but production maturity is still in progress for v0.1.

## Suggested GitHub Descriptions

- `aegis-spec`: Normative Aegis protocol RFCs, schemas, and conformance docs.
- `aegis-core`: Shared Rust crates for Aegis protocol, crypto, identity, and API types.
- `aegit-cli`: Developer/operator CLI for local Aegis workflows and relay interaction.
- `aegis-relay`: Reference zero-trust store-and-forward relay implementation.
- `aegis-sdk`: Thin SDK wrappers over current v0.1.0-alpha behavior.
- `aegis-gateway`: Legacy interoperability boundary and downgrade policy groundwork.
- `aegis-docs`: Public-facing guides, onboarding, architecture, and release runbooks.
