# Changelog

All notable changes to this repository are documented here.

## [Unreleased]

### Glossary expansion (closes #8)

- New `docs/glossary.md` — expanded contributor-facing glossary with ~30 entries grouped by Protocol / Identity / Relay / Gateway / Cryptography. Each entry summarizes the term and cross-links to the canonical RFC, design doc, or source file rather than redefining content. Aliases to the existing 8-entry list at `aegis-spec/docs/glossary.md` (kept as a thin terms-only reference).
- Covers terms across the stack: AMP, Envelope, PrivatePayload, IdentityDocument, PrekeyBundle, Suite, Demo Suite; `amp:did:key:*`, Alias, Domain Claim, Resolver, Self-certifying; Relay, Lifecycle endpoints, Retention policy, Federation, Audit Log; Gateway, Downgrade, Downgrade Policy, Downgrade Audit Event; PQ, Hybrid PQ Suite, ML-KEM-768, ML-DSA-65, KEM, AEAD, Forward Secrecy, Signature Policy, Experimental PQ.
- README.md updated to list the new doc.

### Relay operator guide (closes #6)

- New `docs/relay-operator-guide.md` — concise run-guide for development and self-hosted Aegis relays. Covers the five lifecycle endpoints (push / fetch / ack / delete / cleanup), local-dev token semantics + scope mapping, per-command failure → operator-action tables, the cleanup retention sweep with its three counters and operator knobs (`AEGIS_RELAY_MAX_MESSAGE_AGE_DAYS` / `AEGIS_RELAY_PURGE_ACKED_ON_CLEANUP`), and the typical-day workflow (monitor / audit / cleanup / token rotation / storage backup). Explicitly scoped to dev + self-hosted; production SRE runbooks remain in `aegis-deploy`. Cross-links RFC-0004 as the normative endpoint contract.
- README.md updated to list the new doc.

### Security FAQ (closes #7)

- New `docs/security-faq.md` — humans-language summary of Aegis's security posture as of v0.3.0-alpha. Sections:
  - Trust boundaries: relay (zero-trust), gateway (outside trusted core), discovery endpoint (TLS as trust anchor)
  - Cryptography status: demo suite is **not** production, production hybrid PQ (X25519 + ML-KEM-768 + Ed25519 + ML-DSA-65) is, experimental-pq feature gate semantics, one-time prekey support
  - Identity and resolution: self-certifying `amp:did:key:*`, no central CA, relay-side domain-claim flow, what happens when a relay lies about an alias
  - What's explicitly **not** solved: full metadata privacy, production trust policy, gateway-side downgrade safety, long-term forward secrecy under key compromise
  - Reporting issues + further-reading index
- README.md updated to list the new doc.

### Contributor quickstart (closes #9)

- New `docs/contributor-quickstart.md` — shortest-path setup guide from a fresh checkout to a working local Aegis development loop in ~15 minutes. Covers: alpha caveats, multi-repo clone layout (the four repos needed for local E2E), Rust toolchain setup, per-repo build/test verification, the `aegit-cli/scripts/local-e2e-demo.sh` round-trip script, the `scripts/validate-alpha.sh` sweep, where to go next (table of relevant docs per goal), workflow conventions, and getting-help channels.
- README.md updated to list the new doc in the Documentation Structure section.

### v0.3.0-alpha — phase 1 (relay-side prekey enforcement)

- `architecture.md`: §2.3 (`Envelope`) and §3.3 (Trust Model) updated — relay now atomically enforces `used_prekey_ids` consumption; send-side population is the remaining gap.
- `architecture.md`: §5.4 (Forward Secrecy) rewritten to reflect phase 1 shipped vs phase 2/3 remaining; §6 (What Is NOT Solved Yet) reorganized.
- `docs/v0.2.0-alpha-roadmap.md`: v0.3 section split into phases with phase 1 marked shipped.

### v0.3.0-alpha — FIPS 203 / 204 finalization

- `docs/pq-crypto-research.md`: rewritten "Crate Selection" section. Removes the `pqcrypto-kyber` / `pqcrypto-dilithium` rationale (which acknowledged round-3 vs FIPS as a "future migration") and replaces it with the `ml-kem` / `ml-dsa` (RustCrypto) rationale that's now in production. New "RNG plumbing note" subsection documents the `getrandom::SysRng` + `rand_core::UnwrapErr` pattern used to feed ml-dsa without bumping the workspace `rand 0.8`. "Open Questions for Future Releases" updated: prekeys + ml-kem/ml-dsa migration both marked shipped.

### v0.3.0-alpha — phase 3 (send-side integration; end-to-end forward secrecy)

- `architecture.md` §5.4: rewritten as a four-link chain (generate / publish + claim / seal / push + open + consume) with all four shipped. Explicit forward-secrecy guarantee documented: each one-time prekey participates in exactly one KEM combine; the relay's atomic enforcement prevents replay; recipient consume-on-success deletes the local secret.
- `architecture.md` §6: removed the "send-side prekey integration" gap. The remaining classical (X25519) forward-secrecy gap (would require ephemeral X25519 prekeys) is now explicit.
- `docs/v0.2.0-alpha-roadmap.md`: phase 3 marked shipped with per-repo what-shipped table.

### v0.3.0-alpha — phase 2 (prekey publish + atomic claim)

- `architecture.md` §5.4: documents the publish (`POST /v1/identities/:id/prekeys`) and atomic-claim (`GET /v1/identities/:id/prekey`) endpoints, the published-check that tightens phase 1 (envelopes citing an unknown `key_id` are rejected as `400 unknown_prekey`), and the `aegit id publish-prekeys` CLI flow.
- `architecture.md` §6: removed the "publish + atomic-claim relay endpoints" gap (now shipped); only send-side seal integration remains for phase 3.
- `docs/v0.2.0-alpha-roadmap.md`: phase 2 marked shipped with per-repo what-shipped table.

## [v0.2.0-alpha] - 2026-05-03

### Roadmap + status

- New `docs/v0.2.0-alpha-roadmap.md` capturing shipped v0.2 features and forward plan (v0.3 / v0.4 / v1.0)
- Security model and PQ research notes updated for the production hybrid PQ suite

### Architecture

- `architecture.md` revised to reflect v0.2 reality:
  - Storage: file-backed → SQLite WAL persistence
  - Crypto: demo XChaCha20-Poly1305 → hybrid PQ (X25519 + ML-KEM-768) production suite
  - Identity: schema-only → self-certifying signed documents with HTTP resolver
  - Relay: anonymous endpoints → multi-token auth, structured audit, retention controls, status metrics
  - Gateway: scaffold → SMTP/IMAP boundary with PQ-aware downgrade enforcement

## [v0.1.0-alpha] - 2026-04-29

- Initial public alpha baseline for the Aegis multi-repo project.
- Scope is explicitly draft/prototype and non-production.
- Demo/local-development crypto workflows only; production PQ is not implemented.
