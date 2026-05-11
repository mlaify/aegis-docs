# Contributor Quickstart

Shortest path from a fresh checkout to a working local Aegis development
loop. Roughly 15 minutes if Rust is already installed.

## Alpha caveats — read before contributing

Aegis is **draft / prototype**, not production. Specifically:

- The demo suite (`AMP-DEMO-XCHACHA20POLY1305`) is passphrase-keyed and
  exists only for local development. Do not ship anything that uses it.
- Resolver / identity trust policy is in-progress — see
  `../aegis-spec/rfcs/RFC-0004-relay-api.md`.
- Gateway downgrade flows are scaffold-grade — see
  `../aegis-spec/rfcs/RFC-0006-gateway-and-downgrade-boundary.md`.
- See [security-model.md](./security-model.md) for the current security
  posture and [security-faq.md](./security-faq.md) for common questions.

## 1. Clone the multi-repo workspace

Aegis lives across ~13 repos under `mlaify/aegis-*` (plus `aegit-cli`).
Most contributors only need the four below for a working local E2E loop:

```sh
# Pick a workspace root
mkdir -p ~/code/aegis && cd ~/code/aegis

# Clone the four repos needed for local E2E
git clone git@github.com:mlaify/aegis-core.git
git clone git@github.com:mlaify/aegis-relay.git
git clone git@github.com:mlaify/aegit-cli.git
git clone git@github.com:mlaify/aegis-docs.git
```

The relay and CLI use sibling `../aegis-core` path dependencies, so the
directory layout matters — clone them as siblings under one root.

For the full repository inventory, see
[repository-map.md](./repository-map.md).

## 2. Install Rust + standard components

```sh
# If you don't have rustup yet
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Required components for fmt + clippy
rustup component add rustfmt clippy
```

Aegis builds against stable Rust (no nightly required as of v0.3-alpha).
A recent toolchain (≥ 1.75 for native `async fn` in traits) is needed.

## 3. Verify the four repos build

From the workspace root:

```sh
# aegis-core: workspace crates (proto, crypto, identity, api-types, testkit)
cd aegis-core
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cd ..

# aegis-relay: the reference relay binary
cd aegis-relay
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test
cd ..

# aegit-cli: the operator CLI
cd aegit-cli
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test
cd ..
```

All three workspaces should build with zero warnings. CI runs the same
commands, so if these pass locally CI will too.

## 4. Run the local E2E demo

The CLI ships a complete seal → push → fetch → open round-trip script:

```sh
cd aegit-cli
sh scripts/local-e2e-demo.sh
```

The script:

1. Starts a local relay on `127.0.0.1:8787`
2. Generates two identities (sender + recipient)
3. Seals a demo-suite envelope from sender to recipient
4. Pushes it through the relay
5. Fetches it on the recipient side
6. Opens the envelope and asserts the body round-trips
7. Tears down the local relay

If this passes end-to-end you have a working dev environment.

Detailed setup notes: [aegit-cli/DEV-SETUP.md](../../aegit-cli/DEV-SETUP.md).

## 5. Run the alpha-validation script

```sh
cd aegis-docs
sh scripts/validate-alpha.sh
```

This sweeps through all four repos and runs the canonical checks listed
in the release runbook. Output should end with `validate-alpha: OK`.

If you see failures, the script aborts on the first error — re-run
after fixing.

## 6. Where to go next

| Goal | Read |
|---|---|
| Understand the protocol contracts | [`../aegis-spec/docs/protocol-index.md`](../../aegis-spec/docs/protocol-index.md) |
| See what's implemented vs spec | [`../aegis-spec/docs/implementation-conformance-v0.3.md`](../../aegis-spec/docs/implementation-conformance-v0.3.md) |
| Architecture overview | [architecture-overview.md](./architecture-overview.md) |
| Threat model + non-goals | [security-model.md](./security-model.md), [security-faq.md](./security-faq.md) |
| How relay lifecycle works | [relay-operator-guide.md](./relay-operator-guide.md) |
| Glossary of terms | [glossary.md](./glossary.md) |
| Test matrix | [test-matrix-v0.1.md](./test-matrix-v0.1.md) |
| Release process | [release-runbook.md](./release-runbook.md) |
| Per-repo development | each repo's `CONTRIBUTING.md` |

## 7. Workflow conventions

- **One topic per PR**. Small focused PRs land faster.
- **CHANGELOG entry per user-facing change** per Keep a Changelog
  conventions. Most repos have an `[Unreleased]` section ready.
- **Tests with new behavior**. Pure refactors are fine without; new
  features should land with coverage.
- **Squash-merge** is the default; the repo's CI gate plus the
  org-level review ruleset enforce this.
- **CI is canonical**. If `cargo fmt --check`, `cargo clippy --
  -D warnings`, and `cargo test` pass locally on the four repos, CI
  will pass.

For per-repo specifics (Rust crate layout, transport scaffolds, FFI
boundaries, etc.) read the repo's own `CONTRIBUTING.md` after this
quickstart.

## 8. Getting help

- File issues on the repo most directly affected. If you're not sure,
  `aegis-docs` is a fine default.
- Security issues: see [SECURITY.md](../SECURITY.md) — disclose
  privately via the channels listed there.
- Sketches of larger ideas: open a `protocol_change` issue on
  `aegis-spec` so the conversation lives next to the affected RFCs.
