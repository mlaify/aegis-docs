# Aegis v0.1 Test Matrix

Status: Human-readable implementation test map for v0.1.0-alpha.

| Feature | Repo | Test command | Status | Related RFC |
|---|---|---|---|---|
| Serialization fixtures (Envelope/PrivatePayload/IdentityDocument/PrekeyBundle) | `aegis-core` | `cd aegis-core && cargo test -p aegis-proto` | implemented | RFC-0002, RFC-0003 |
| Demo crypto payload round trip | `aegis-core` | `cd aegis-core && cargo test -p aegis-crypto` | implemented | RFC-0005 |
| Local identity create/show/list | `aegit-cli` | `cd aegit-cli && cargo test` and `cargo run -- id init/show/list` | implemented | RFC-0002 |
| Signing key material persistence (local-dev) | `aegit-cli`, `aegis-core` | `cd aegis-core && cargo test -p aegis-identity`; `cd aegit-cli && cargo test` | implemented | RFC-0002, RFC-0005 |
| Signature status reporting in `msg open` | `aegit-cli` | `cd aegit-cli && cargo test` and `sh scripts/local-e2e-demo.sh` | implemented | RFC-0003 |
| Relay store/fetch | `aegis-relay`, `aegit-cli` | `cd aegis-relay && cargo test`; `cd aegit-cli && sh scripts/local-e2e-demo.sh` | implemented | RFC-0004 |
| Relay structural validation before storage | `aegis-relay` | `cd aegis-relay && cargo test` | implemented | RFC-0004 |
| Relay `expires_at` filtering | `aegis-relay` | `cd aegis-relay && cargo test` | implemented | RFC-0004 |
| Relay ack/delete lifecycle | `aegis-relay`, `aegit-cli` | `cd aegis-relay && cargo test`; `cd aegit-cli && sh scripts/local-e2e-demo.sh` | implemented | RFC-0004 |
| Relay cleanup (expired + orphan ack) | `aegis-relay`, `aegit-cli` | `cd aegis-relay && cargo test`; `cd aegit-cli && sh scripts/local-e2e-demo.sh` | implemented | RFC-0004 |
| Local-dev token-gated lifecycle auth | `aegis-relay`, `aegit-cli` | `cd aegis-relay && cargo test`; `cd aegit-cli && sh scripts/local-e2e-demo.sh` | implemented | RFC-0004 |
| Experimental PQ feature tests (`kyber768`) | `aegis-core` | `cd aegis-core && cargo test -p aegis-crypto --features experimental-pq` | partial (experimental only) | RFC-0005 |
| SDK seal/open wrapper | `aegis-sdk` | `cd aegis-sdk/rust && cargo test` | implemented | RFC-0001, RFC-0003, RFC-0005 |
| Gateway policy evaluation (reject/allow_with_warning/require_user_confirmation) | `aegis-gateway` | `cd aegis-gateway && cargo test` | implemented (policy-only) | RFC-0006 |

## Known Gaps

- No production relay authn/authz model (local-dev token gating only).
- No production PQ deployment.
- No production resolver service.
- No SMTP/IMAP gateway bridge implementation.
