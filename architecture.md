# Aegis Architecture

## Scope and Status

This document describes the Aegis architecture as implemented in `v0.2.0-alpha`, and separates it from planned future architecture.

Aegis is an asynchronous secure messaging system built around cryptographic identity, end-to-end encrypted payloads, and zero-trust relay infrastructure.

## Current vs Future (Read This First)

### Current architecture (implemented in v0.2.0-alpha)

- Protocol definitions exist in `aegis-spec` RFCs and JSON schemas (RFCs 0001–0006).
- `Envelope` and `PrivatePayload` wire models are implemented in `aegis-core` (`aegis-proto`).
- CLI flows for `id init`, `id publish`, `id show`, `id list`, `msg seal`, `msg open`, `relay push`, `relay fetch`, `relay ack`, `relay delete`, `relay cleanup` are implemented via `aegit-cli`.
- A reference HTTP relay exists in `aegis-relay` with **SQLite WAL persistence** via `tokio-rusqlite`.
- Identity addressing format is defined (`amp:did:key:<identifier>`); identity documents are self-certifying (Ed25519-signed) and resolvable over HTTP via the relay.
- Aliases are non-authoritative names indexed for O(1) lookup at the relay.
- A **production hybrid post-quantum suite** is implemented: `AMP-HYBRID-PQ-V1` combines X25519 + ML-KEM-768 via HKDF-SHA256, with XChaCha20-Poly1305 AEAD.
- A demo symmetric suite remains available for local development (`DemoXChaCha20Poly1305`).
- Envelope signing/verification implemented for both Ed25519 and Dilithium3 (ML-DSA-65).
- Relay authentication (multi-token, per-scope), structured JSONL audit logging, and retention controls are implemented.
- Legacy email gateway (`aegis-gateway`) provides RFC 5321 SMTP inbound, IMAP4rev1, and `lettre`-based SMTP outbound, with downgrade policy enforced at the SMTP DATA boundary.

### Future architecture (planned, not implemented yet)

- Operational prekey lifecycle: atomic single-use enforcement of `used_prekey_ids` (v0.3).
- Key rotation with relay-tracked epochs (v0.3).
- Full MIME transformation in the gateway: attachments, HTML multipart, inline images (v0.3).
- Production client applications: web, desktop, mobile (v0.3 / v0.4).
- Attachment blob transport with per-attachment content keys (v0.4).
- Thread model (`thread_id` / `in_reply_to`) wired through clients (v0.4).
- Federated multi-relay routing and cross-relay delivery (v1.0).
- Rate limiting and abuse controls beyond per-token scoping (v1.0).
- External security audit; FIPS 203/204 KAT test vectors (v1.0).

---

## 1. High-Level System Model

Aegis is layered so that trust decisions happen at the identity and client edges, while transport infrastructure is intentionally untrusted.

### 1.1 Identity layer

Purpose:

- Represent actor identity as cryptographic continuity, not DNS ownership.
- Bind usable aliases to a cryptographic identity root.
- Advertise key material and supported suites.

Current implementation status:

- Canonical identity format defined in RFC-0002: `amp:did:key:<identifier>`.
- `IdentityDocument` and `PrekeyBundle` schemas implemented in `aegis-identity`.
- Identity documents are self-certifying: signed with the holder's Ed25519 signing key and verified by `verify_identity_document_signature()` before acceptance.
- HTTP identity resolver (`resolver.rs`) fetches identity documents from a relay by canonical id or alias.
- Key rotation policy and prekey consumption enforcement remain future work (v0.3).

### 1.2 Message layer

Purpose:

- Define how message data is serialized, encrypted, and encapsulated.
- Separate relay-visible metadata from private content.

Current implementation status:

- `Envelope` and `PrivatePayload` are implemented in JSON form.
- `aegit msg seal` encrypts `PrivatePayload` into `Envelope.payload` using the suite advertised by the recipient identity (hybrid PQ when available, demo otherwise).
- `aegit msg open` decrypts and materializes `PrivatePayload` locally.
- Envelope outer signatures (Ed25519 or Dilithium3) are produced and verified by `EnvelopeSigner` / `EnvelopeVerifier`.

### 1.3 Transport layer

Purpose:

- Store and forward opaque encrypted envelopes asynchronously.
- Allow recipients to fetch while offline-tolerant delivery is preserved.

Current implementation status:

- Reference relay implemented over HTTP with the following endpoints:
  - `GET /healthz`
  - `GET /v1/status` — operator metrics (envelope/identity counts, auth config)
  - `POST /v1/envelopes` — push envelope (auth-scoped: `PushEnvelope`)
  - `GET /v1/envelopes/:recipient_id` — list envelopes for a recipient
  - `GET /v1/envelopes/:recipient_id/:envelope_id` — fetch a specific envelope
  - `DELETE /v1/envelopes/:recipient_id/:envelope_id` — delete after ack (auth-scoped: `LifecycleChange`)
  - `POST /v1/envelopes/:recipient_id/:envelope_id/ack` — acknowledge receipt
  - `POST /v1/cleanup` — operator-triggered retention pass (auth-scoped: `LifecycleChange`)
  - `PUT /v1/identities/:id` — publish identity document (auth-scoped: `IdentityWrite`)
  - `GET /v1/identities/:id` — resolve identity by canonical id
  - `GET /v1/aliases/:alias` — resolve identity by alias (O(1) indexed lookup)
- Relay persists envelopes and identity documents in **SQLite with WAL journaling** via `tokio-rusqlite` (`storage.rs`).
- Relay does not decrypt payloads.
- HybridPq envelope wire fields are validated on ingest.

### 1.4 Client layer

Purpose:

- Own secrets and local trust policy.
- Perform message sealing/opening.
- Manage local state and relay interactions.

Current implementation status:

- CLI client (`aegit-cli`) is the working client surface, with full identity, message, and relay workflows.
- Local identity persistence under `~/.aegis/aegit/`.
- End-user applications in `aegis-client` (web, desktop, mobile) remain scaffolds; production clients are planned for v0.3 / v0.4.

### 1.5 Gateway layer

Purpose:

- Isolate interoperability with legacy email systems from core protocol guarantees.
- Contain downgrade pressure at a boundary service rather than core identity/message primitives.

Current implementation status:

- `aegis-gateway` runs an RFC 5321 SMTP inbound server (`smtp_server.rs`) and an IMAP4rev1 server (`imap_server.rs`) for legacy clients.
- Outbound SMTP delivery via `lettre` (`smtp_client.rs`).
- Downgrade policy is PQ-aware and is enforced at the SMTP DATA boundary: the `X-Aegis-Suite` header is parsed and the configured `DowngradeMode` (`AEGIS_GATEWAY_DOWNGRADE_MODE`) evaluated before message wrapping.
- `X-Aegis-Identity` header drives SMTP-to-Aegis routing, with `amp:did:key:` RCPT TO as fallback.
- `X-Aegis-Downgrade-Confirmed: true` is required when `downgrade_mode=require_user_confirmation`.
- Full MIME transformation (attachments, HTML multipart, inline images) is deferred to v0.3.

---

## 2. Core Objects

These objects are defined in RFCs/schemas and implemented in runtime code.

### 2.1 `IdentityDocument`

Role:

- Canonical identity descriptor for an actor.
- Carries key references, supported suites, and relay endpoint hints.

Schema fields:

- `version`
- `identity_id`
- `aliases[]`
- `signing_keys[]`
- `encryption_keys[]`
- `supported_suites[]`
- `relay_endpoints[]`
- `signature` (Ed25519 over canonical document bytes)

Current status:

- Schema-defined contract implemented and signed.
- Signature verification enforced on relay publish and on client resolve.
- Key rotation policy remains future work (v0.3).

### 2.2 `PrekeyBundle`

Role:

- Publishes prekey material and suite support for asynchronous session setup patterns.

Schema fields:

- `identity_id`
- `signed_prekeys[]`
- `one_time_prekeys[]`
- `supported_suites[]`
- `expires_at` (nullable)
- `signature` (nullable)

Current status:

- Schema-defined contract exists.
- Runtime atomic single-use enforcement of `used_prekey_ids` is **not yet implemented** — targeted for v0.3. This is the primary blocker on a real forward-secrecy story.

### 2.3 `Envelope`

Role:

- Relay-transportable wrapper for encrypted private payload.
- Contains minimal metadata needed for asynchronous routing/storage.

Implemented fields (`aegis_proto::Envelope`):

- `version`
- `envelope_id`
- `recipient_id`
- `sender_hint` (nullable)
- `created_at`
- `expires_at` (nullable)
- `content_type`
- `suite_id` (e.g. `AMP-HYBRID-PQ-V1`)
- `used_prekey_ids[]` (carried but not yet enforced)
- `payload` (`nonce_b64`, `ciphertext_b64`)
- `outer_signature_b64` (Ed25519 or Dilithium3, verified at open)

Current status:

- Fully implemented as JSON model and relay payload contract.
- Outer signatures produced and verified end-to-end.
- `used_prekey_ids` consumption is enforced atomically by the relay (v0.3 phase 1): each `(recipient_id, key_id)` pair is recorded once-and-only-once in the same transaction as the envelope insert; replay is rejected with `409 prekey_already_used`. Send-side population of the field by `aegit msg seal` is targeted for v0.3 phase 3.

### 2.4 `PrivatePayload`

Role:

- End-to-end encrypted message content.
- Contains user-visible message semantics not intended for relay plaintext access.

Implemented fields:

- `private_headers`
  - `subject` (nullable)
  - `thread_id` (nullable)
  - `in_reply_to` (nullable)
- `body`
  - `mime`
  - `content`
- `attachments[]` (manifest only)
- `extensions`

Current status:

- Implemented for local seal/open and JSON wire representation.
- Attachment blob transport (per-attachment content keys + blob upload/download endpoints) is future work (v0.4).

---

## 3. Trust Model

### 3.1 Why relays are untrusted

Aegis assumes relay operators may be curious, compromised, or malicious. This is explicitly in-scope in the threat model.

Design implication:

- Relays store and forward envelopes.
- Relays are not trusted with plaintext and do not require access to private payload content.
- Relays do verify identity document signatures (because identity is self-certifying), but do not verify private payload content.

This is the zero-trust relay stance: infrastructure availability is useful, infrastructure trust is minimized.

### 3.2 Why identity replaces domains

Domain ownership is an operational naming mechanism, not a robust cryptographic identity anchor. Aegis roots trust in cryptographic identity continuity (`amp:did:key:...`) and treats aliases as convenience labels.

Design implication:

- Identity verification is based on keys and signed identity material.
- Domain/provider transitions do not redefine trust identity.

### 3.3 Where trust is enforced

Current trust enforcement points:

- Sender/recipient clients: encryption/decryption, envelope signature verification, local policy.
- Core protocol/data libraries (`aegis-core`): canonical security-sensitive object semantics, signature verification, suite selection.
- Relay: identity document signature verification on publish; per-token, per-scope authentication on write paths; structured audit of all writes.

Current non-enforcement points (by design or not yet implemented):

- Relay plaintext inspection (not required, not trusted).
- Send-side prekey consumption: `aegit msg seal` does not yet populate `used_prekey_ids` from a relay-claimed one-time prekey (v0.3 phase 3); the relay-side enforcement primitive landed in v0.3 phase 1.
- Key rotation and epoch tracking (planned v0.3).
- Federated cross-relay trust (planned v1.0).

---

## 4. Data Flow: `seal -> push -> store -> fetch -> open`

The implemented reference flow.

### Step 1: `seal` (client-side)

- Input: plaintext message intent + recipient identity (resolved from alias or `amp:did:key:` via the relay's identity endpoints) + local key material.
- Action: client constructs `PrivatePayload`, encrypts it under the recipient-advertised suite (hybrid PQ when available), and embeds the encrypted blob in an `Envelope`. Signs the envelope.
- Output: one signed envelope JSON object.

Current command:

- `aegit msg seal`

### Step 2: `push` (client to relay)

- Input: sealed envelope JSON.
- Action: client POSTs `StoreEnvelopeRequest` to the relay, presenting an auth token with `PushEnvelope` scope.
- Output: relay acceptance response (`accepted`, `relay_id`).

Current command and endpoint:

- `aegit relay push`
- `POST /v1/envelopes`

### Step 3: `store` (relay-side)

- Relay validates HybridPq wire fields if applicable.
- Relay persists the envelope row in SQLite (WAL journaling) keyed by recipient and envelope id.
- Relay treats the payload blob as an opaque ciphertext container.
- Relay emits a structured audit event for the write.

Current storage model:

- SQLite database (default `./relay.db`); schema includes `envelopes`, `identities`, `identity_aliases`, and audit/retention metadata tables.

### Step 4: `fetch` (client from relay)

- Recipient client requests queued envelopes for a recipient identity.
- Relay returns the list (or empty list).

Current command and endpoint:

- `aegit relay fetch`
- `GET /v1/envelopes/:recipient_id`

### Step 5: `open` (client-side)

- Input: fetched envelope JSON + local secret material.
- Action: client verifies the outer signature, then decrypts `Envelope.payload` and reconstructs `PrivatePayload`.
- Output: plaintext payload fields for local use.

Current command:

- `aegit msg open`

### Step 6: `ack` / `delete` (client-side, optional)

- Recipient may acknowledge receipt or request deletion of an envelope, both subject to the relay's auth/retention policy.

---

## 5. Security Properties

The following reflects current implementation and planned hardening.

### 5.1 Confidentiality

Current:

- `PrivatePayload` content is encrypted before relay submission using the production hybrid PQ suite (X25519 + ML-KEM-768 → HKDF-SHA256 → XChaCha20-Poly1305).
- Relay storage/API paths operate on envelope ciphertext containers.

Limits today:

- Metadata minimization is incomplete; envelope metadata (recipient, timestamps, sender_hint) remains relay-visible by design.
- Production crypto is not yet third-party audited.

### 5.2 Integrity

Current:

- Hybrid PQ AEAD provides cipher-based tamper detection on the ciphertext blob.
- Outer envelope signature (`outer_signature_b64`) is verified at `open` (Ed25519 or Dilithium3).

Not complete yet:

- Canonical serialization rules for strict cross-implementation integrity remain in active spec work.

### 5.3 Authenticity

Current:

- Self-certifying `IdentityDocument` signatures verified on publish and resolve.
- Outer envelope signatures bind sender identity to message contents.
- `sender_hint` is informational; the outer signature is the trust anchor.

Not complete yet:

- Forward secrecy via prekey single-use (see 5.4).
- Key rotation continuity proofs.

### 5.4 Forward Secrecy (in flight)

Current (v0.3 phase 1, shipped):

- Prekey objects and `used_prekey_ids` field exist on the envelope.
- Relay enforces atomic single-use of one-time prekeys: `(recipient_id, key_id)` is recorded in a `consumed_prekeys` table within the same SQLite transaction as the envelope insert. Replay or any conflict rolls the entire write back and surfaces as `409 prekey_already_used` (RFC-0003 §12, RFC-0004 §17).

Remaining (v0.3 phases 2 + 3):

- Phase 2: prekey publish (`POST /v1/identities/:id/prekeys`) and atomic claim (`GET /v1/identities/:id/prekey`) endpoints; `aegit id init` to generate an initial bundle; `aegit id publish-prekeys` command.
- Phase 3: `aegit msg seal` claims a one-time prekey via the relay and binds the KEM/AEAD context to the consumed prekey public key. Forward secrecy is realized end-to-end at this point.

---

## 6. What Is NOT Solved Yet

Important explicit non-goals or incomplete areas as of `v0.2.0-alpha` plus the in-flight v0.3 phase 1.

- Prekey publish and atomic-claim relay endpoints (v0.3 phase 2).
- Send-side prekey integration in `aegit msg seal` to realize end-to-end forward secrecy (v0.3 phase 3).
- Key rotation with relay-tracked epochs (v0.3).
- Full MIME transformation in the legacy gateway: attachments, HTML multipart, inline images (v0.3).
- Production client applications: web, desktop, mobile (v0.3 / v0.4).
- Attachment blob transport beyond manifest references (v0.4).
- Thread model (`thread_id` / `in_reply_to`) wired through end-user surfaces (v0.4).
- Federation and relay-to-relay interoperability (v1.0).
- Strong metadata privacy beyond baseline envelope model (v1.0+).
- Server-side pagination for large fetch sets (v1.0).
- `expires_at` enforcement at the relay beyond the manual cleanup pass (v1.0).
- Rate limiting and abuse controls beyond per-token scope (v1.0).
- External security audit and FIPS 203/204 KAT test vectors (v1.0).

---

## Architectural Boundary Summary

In `v0.2.0-alpha`, Aegis provides a working reference path for asynchronous secure messaging with:

- **Production hybrid post-quantum** confidentiality and integrity end-to-end.
- **Self-certifying identity** with HTTP resolver and signature verification on every trust boundary.
- **Durable relay storage** (SQLite WAL) with multi-token scoped auth, structured audit, and retention controls.
- **Legacy email interop** via SMTP/IMAP boundary with PQ-aware downgrade enforcement.

The next architectural phase (v0.3) is focused on **key lifecycle**: prekey single-use enforcement, key rotation with epochs, and broadening the legacy bridge with full MIME transformation. After that (v0.4), production client applications and real attachment transport.
