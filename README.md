# Aegis Workspace

This repository is the integration workspace for the Aegis reference stack.

It is not a single deployable service. It is the place where protocol specs, shared core crates, and reference implementations evolve together.

## Purpose of This Repository

This repo exists to keep the Aegis protocol and implementations aligned in one working tree during early-stage development (`v0.1` draft).

It contains:

- protocol specifications and schemas,
- shared Rust protocol/crypto/API crates,
- a runnable relay,
- an operator CLI,
- gateway/client/sdk scaffolding.

## How It Fits Into Aegis

Aegis is organized as logical repositories/components:

- `aegis-spec`: protocol definitions
- `aegis-core`: shared Rust crates
- `aegit-cli`: operator CLI
- `aegis-relay`: message relay server
- `aegis-gateway`: legacy boundary
- `aegis-client`: user apps
- `aegis-sdk`: developer integrations

This workspace hosts those components together so protocol changes can be implemented and validated end-to-end.

## What Is Implemented Right Now

Implemented and usable today:

- Draft RFCs and JSON schemas (`aegis-spec`).
- Core message model crates (`aegis-core`), including `Envelope` and `PrivatePayload`.
- Reference relay HTTP API (`aegis-relay`):
  - `GET /healthz`
  - `POST /v1/envelopes`
  - `GET /v1/envelopes/:recipient_id`
- CLI workflow (`aegit-cli`) for:
  - `id init`, `id show`
  - `msg seal`, `msg open`, `msg list`
  - `relay push`, `relay fetch`
- Local end-to-end loop: `seal -> push -> fetch -> open`.

Still draft / incomplete:

- production crypto suite and migration policy,
- signature enforcement and prekey lifecycle,
- relay authn/authz and lifecycle APIs,
- federation and mature gateway compatibility behavior.

## Build and Run

Prerequisites:

- Rust toolchain (stable)

Build core crates:

```bash
cd aegis-core
cargo build
```

Run relay server (listens on `127.0.0.1:8787`):

```bash
cd aegis-relay
cargo run
```

Run CLI:

```bash
cd aegit-cli
cargo run -- --help
```

Build gateway stub:

```bash
cd aegis-gateway
cargo build
```

Optional checks:

```bash
cd aegis-core && cargo test
cd ../aegis-relay && cargo test
cd ../aegit-cli && cargo test
```

## Planned Next

Near-term priorities for this workspace:

- tighten protocol semantics from RFC draft to enforceable behavior,
- move from demo crypto paths to production-grade suites,
- add signature/authenticity and prekey lifecycle enforcement,
- harden relay behavior (auth, retention, pagination, deletion, policy),
- stabilize SDK/client integration surfaces around the core protocol.

## Notes

Treat current wire formats and APIs as draft-track. Pin versions and expect breaking changes while RFCs move toward stability.
