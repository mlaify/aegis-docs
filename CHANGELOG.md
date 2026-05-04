# Changelog

All notable changes to this repository are documented here.

## [Unreleased]

- Ongoing `v0.2.0-alpha` stabilization.

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
