# Aegis Documentation

This repository (`aegis-docs`) is the documentation home for the Aegis system.

It describes both:

- the Aegis root workspace folder used for integrated development, and
- the broader multi-repo architecture under `github.com/mlaify`.

## Repository Context

- Organization: `github.com/mlaify`
- Documentation repo: `aegis-docs`
- Local integrated workspace folder: `aegis/` (contains multiple Aegis component directories for coordinated development)

## Aegis Root Folder (`aegis/`)

The `aegis/` root folder is an integration workspace where protocol specs and implementations are developed and tested together.

Typical contents in the root workspace:

- `aegis-spec/`
- `aegis-core/`
- `aegit-cli/`
- `aegis-relay/`
- `aegis-gateway/`
- `aegis-client/`
- `aegis-sdk/`
- `aegis-docs/`

Use this workspace when you need cross-repo changes, local end-to-end validation, or coordinated protocol updates.

## Aegis Repositories and Roles

- `aegis-spec`
  - Protocol RFCs, schemas, and canonical wire contracts.
- `aegis-core`
  - Shared Rust crates for protocol objects, crypto traits, identity helpers, API types, and test utilities.
- `aegit-cli`
  - Operator/developer CLI for identity setup, message seal/open, and relay push/fetch flows.
- `aegis-relay`
  - Reference relay server (store-and-forward for sealed envelopes).
- `aegis-gateway`
  - Legacy interoperability boundary to isolate downgrade/compatibility concerns from protocol core.
- `aegis-client`
  - User-facing application surfaces (desktop/web/mobile).
- `aegis-sdk`
  - Developer integration surfaces and language SDKs.
- `aegis-docs`
  - Architecture, threat model, philosophy, and system-level documentation.

## What `aegis-docs` Contains

- [Architecture](./architecture.md)
  - System layers, core objects, trust model, and current vs future architecture.
- [Threat Model](./threat-model.md)
  - Protections, partial protections, explicit non-goals, and assumptions.
- [Design Philosophy](./philosophy.md)
  - Security and protocol design principles that guide Aegis direction.

## Recommended Reading Order

1. [Design Philosophy](./philosophy.md)
2. [Architecture](./architecture.md)
3. [Threat Model](./threat-model.md)

## Documentation Conventions

- Identity is cryptographic (`amp:did:key:...`), not domain-authority based.
- End-to-end encryption is the default model for private payload content.
- Relays are treated as untrusted for plaintext access.
- Compatibility with legacy systems is treated as a boundary concern.

## Status

Aegis is currently in draft-stage protocol development. Documentation is explicit about what is implemented now versus what is planned next.
