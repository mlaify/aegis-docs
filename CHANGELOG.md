# Changelog

All notable changes to this repository are documented here.

## [Unreleased]

### v0.3.0-alpha — phase 1 (relay-side prekey enforcement)

- `architecture.md`: §2.3 (`Envelope`) and §3.3 (Trust Model) updated — relay now atomically enforces `used_prekey_ids` consumption; send-side population is the remaining gap.
- `architecture.md`: §5.4 (Forward Secrecy) rewritten to reflect phase 1 shipped vs phase 2/3 remaining; §6 (What Is NOT Solved Yet) reorganized.
- `docs/v0.2.0-alpha-roadmap.md`: v0.3 section split into phases with phase 1 marked shipped.

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
