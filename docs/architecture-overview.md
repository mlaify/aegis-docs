# Architecture Overview

Aegis is organized as a multi-repo system with clear boundaries.

## Core Principle

- `aegis-spec` defines protocol truth.
- `aegis-core` defines shared implementation primitives.
- CLI/relay/SDK consume core primitives.

## Repositories

- `aegis-spec`: RFCs, schemas, conformance mapping.
- `aegis-core`: protocol, crypto, identity, API type crates.
- `aegit-cli`: local operator/developer workflows.
- `aegis-relay`: zero-trust reference relay.
- `aegis-sdk`: thin wrappers over current v0.1 behavior.

## Normative References

- `../aegis-spec/docs/protocol-index.md`
- `../aegis-spec/rfcs/RFC-0001-aegis-message-protocol-overview.md`
- `../aegis-spec/rfcs/RFC-0003-envelopes-and-private-payloads.md`
- `../aegis-spec/rfcs/RFC-0004-relay-api.md`
