# Aegis Architecture

## Scope and Status

This document describes the Aegis architecture as implemented in the current `v0.1` draft stage, and separates it from planned future architecture.

Aegis is an asynchronous secure messaging system built around cryptographic identity, end-to-end encrypted payloads, and zero-trust relay infrastructure.

## Current vs Future (Read This First)

### Current architecture (implemented now)

- Draft protocol definitions exist in `aegis-spec` RFCs and JSON schemas.
- `Envelope` and `PrivatePayload` wire models are implemented in `aegis-core` (`aegis-proto`).
- CLI flows for `seal`, `push`, `fetch`, and `open` are implemented via `aegit-cli`.
- A reference HTTP relay exists in `aegis-relay` with file-backed envelope storage.
- Identity addressing format is defined (`amp:did:key:<identifier>`), and aliases are treated as non-authoritative.
- A demo symmetric suite is used for local development (`DemoXChaCha20Poly1305`).

### Future architecture (planned, not implemented yet)

- Production key exchange and signature verification flows.
- Operational prekey lifecycle use (`used_prekey_ids` population/validation).
- Authenticated and authorized relay APIs.
- Federated multi-relay routing and cross-relay delivery.
- Robust message lifecycle semantics (pagination, deletion, expiry enforcement).
- Post-quantum suite migration and hardened cryptographic agility.

---

## 1. High-Level System Model

Aegis is layered so that trust decisions happen at the identity and client edges, while transport infrastructure is intentionally untrusted.

### 1.1 Identity layer

Purpose:

- Represent actor identity as cryptographic continuity, not DNS ownership.
- Bind usable aliases to a cryptographic identity root.
- Advertise key material and supported suites.

Current implementation status:

- Canonical identity format is defined in RFC-0002: `amp:did:key:<identifier>`.
- `IdentityDocument` and `PrekeyBundle` schemas exist and define intended contracts.
- Full verification and lifecycle enforcement are not yet wired through runtime paths.

### 1.2 Message layer

Purpose:

- Define how message data is serialized, encrypted, and encapsulated.
- Separate relay-visible metadata from private content.

Current implementation status:

- `Envelope` and `PrivatePayload` are implemented in JSON form.
- `aegit msg seal` encrypts `PrivatePayload` into `Envelope.payload`.
- `aegit msg open` decrypts and materializes `PrivatePayload` locally.

### 1.3 Transport layer

Purpose:

- Store and forward opaque encrypted envelopes asynchronously.
- Allow recipients to fetch while offline-tolerant delivery is preserved.

Current implementation status:

- Reference relay API is implemented over HTTP (`GET /healthz`, `POST /v1/envelopes`, `GET /v1/envelopes/:recipient_id`).
- Relay persists envelope JSON files to local filesystem storage.
- Relay does not decrypt payloads.

### 1.4 Client layer

Purpose:

- Own secrets and local trust policy.
- Perform message sealing/opening.
- Manage local state and relay interactions.

Current implementation status:

- CLI client (`aegit-cli`) is the working client surface.
- Message workflow is available end-to-end in local dev.
- Rich end-user apps in `aegis-client` are present as repo structure, but protocol-critical flows are currently demonstrated through CLI/reference components.

### 1.5 Gateway layer

Purpose:

- Isolate interoperability with legacy email systems from core protocol guarantees.
- Contain downgrade pressure at a boundary service rather than core identity/message primitives.

Current implementation status:

- `aegis-gateway` exists as the designated compatibility boundary.
- Core downgrade and compatibility semantics are not fully implemented yet.

---

## 2. Core Objects

These objects are defined in RFCs/schemas and partially implemented in runtime code.

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
- `signature` (nullable)

Current status:

- Schema-defined contract exists.
- Full signature verification and key-rotation policy enforcement remain future work.

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
- Runtime prekey consumption and validation logic is not fully implemented in v0.1.

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
- `suite_id`
- `used_prekey_ids[]`
- `payload` (`nonce_b64`, `ciphertext_b64`)
- `outer_signature_b64` (nullable)

Current status:

- Fully implemented as JSON model and relay payload contract.
- Signature field and prekey list are currently placeholders for future cryptographic workflows.

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
- `attachments[]`
- `extensions`

Current status:

- Implemented for local seal/open and JSON wire representation.
- Attachment transfer protocol beyond manifest references is future work.

---

## 3. Trust Model

### 3.1 Why relays are untrusted

Aegis assumes relay operators may be curious, compromised, or malicious. This is explicitly in-scope in the threat model.

Design implication:

- Relays are expected to store and forward envelopes.
- Relays are not trusted with plaintext and should not require access to private payload content.

This is the zero-trust relay stance: infrastructure availability is useful, infrastructure trust is minimized.

### 3.2 Why identity replaces domains

Domain ownership is an operational naming mechanism, not a robust cryptographic identity anchor. Aegis roots trust in cryptographic identity continuity (`amp:did:key:...`) and treats aliases as convenience labels.

Design implication:

- Identity verification should be based on keys and signed identity material.
- Domain/provider transitions do not redefine trust identity.

### 3.3 Where trust is enforced

Current trust enforcement points:

- Sender/recipient clients: encryption/decryption and local policy.
- Core protocol/data libraries (`aegis-core`): canonical security-sensitive object semantics.

Current non-enforcement points (by design or not yet implemented):

- Relay plaintext inspection (not required, not trusted).
- Full runtime validation of signatures, prekey usage, and expiry (planned future hardening).

---

## 4. Data Flow: `seal -> push -> store -> fetch -> open`

The implemented reference flow is intentionally simple and auditable.

### Step 1: `seal` (client-side)

- Input: plaintext message intent + recipient identity context + local passphrase/demo suite parameters.
- Action: client constructs `PrivatePayload`, encrypts it, and embeds encrypted blob in an `Envelope`.
- Output: one envelope JSON object.

Current command:

- `aegit msg seal`

### Step 2: `push` (client to relay)

- Input: sealed envelope JSON.
- Action: client POSTs `StoreEnvelopeRequest` to relay endpoint.
- Output: relay acceptance response (`accepted`, `relay_id`).

Current command and endpoint:

- `aegit relay push`
- `POST /v1/envelopes`

### Step 3: `store` (relay-side)

- Relay persists envelope as JSON file under recipient-partitioned storage path.
- Relay treats payload blob as opaque ciphertext container.

Current storage model:

- `./data/<sanitized_recipient_id>/<envelope_id>.json`

### Step 4: `fetch` (client from relay)

- Recipient client requests all queued envelopes for a recipient identity.
- Relay returns list of envelope objects (or empty list).

Current command and endpoint:

- `aegit relay fetch`
- `GET /v1/envelopes/:recipient_id`

### Step 5: `open` (client-side)

- Input: fetched envelope JSON + local secret material/passphrase.
- Action: client decrypts `Envelope.payload` and reconstructs `PrivatePayload`.
- Output: plaintext payload fields for local use.

Current command:

- `aegit msg open`

---

## 5. Security Properties

The following reflects current implementation and planned hardening.

### 5.1 Confidentiality

Current:

- `PrivatePayload` content is encrypted before relay submission.
- Relay storage/API paths operate on envelope ciphertext containers.

Limits today:

- Metadata minimization is incomplete; envelope metadata remains relay-visible by design.
- Demo cryptographic suite is for local development, not production assurance.

### 5.2 Integrity

Current:

- Cipher-based tamper detection depends on the currently selected suite behavior during `open`.

Not complete yet:

- End-to-end signed envelope integrity (`outer_signature_b64`) is not enforced in current runtime.
- Canonical serialization rules for strict cross-implementation integrity are still draft-stage.

### 5.3 Authenticity

Current:

- Identity model and schema fields establish the intended authenticity framework.
- `sender_hint` is present but not a trust anchor by itself.

Not complete yet:

- Strong sender authenticity checks via verified signatures and key-chain continuity are future work.

### 5.4 Forward Secrecy (future)

Current:

- Prekey objects and fields exist, but live prekey lifecycle semantics are not fully wired.

Future direction:

- Enforce prekey use and one-time/signed prekey rotation.
- Bind message/session cryptography to verified prekey material for forward secrecy properties.

---

## 6. What Is NOT Solved Yet

These are important, explicit non-goals or incomplete areas in current `v0.1` architecture.

- Production-grade cryptographic suite selection and migration policy.
- End-to-end signature verification and sender authenticity enforcement.
- Full prekey lifecycle management and forward secrecy guarantees.
- Relay authentication, authorization, and abuse controls.
- Federation and relay-to-relay interoperability model.
- Strong metadata privacy beyond baseline envelope model.
- Server-side pagination, deletion, acknowledgement, and mature retention semantics.
- Expiry enforcement (`expires_at`) in production relay/client behavior.
- Durable storage backends beyond local filesystem reference implementation.
- Hardened legacy gateway downgrade protections beyond boundary placement.

---

## Architectural Boundary Summary

Aegis currently provides a working reference path for secure asynchronous messaging with identity-first design and untrusted transport assumptions.

In `v0.1`, the strongest guarantees come from endpoint-controlled encryption and protocol layering discipline. The next architectural phase is focused on cryptographic hardening, trust enforcement completeness, and operational-scale transport behavior.
