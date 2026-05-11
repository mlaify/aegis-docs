# Glossary

Terminology used across the Aegis multi-repo project. Entries link to
the canonical RFC or design doc when one exists; this glossary
summarizes rather than redefines.

A shorter terms-only list also lives at
[`../../aegis-spec/docs/glossary.md`](../../aegis-spec/docs/glossary.md).
This page is the expanded contributor-facing version.

---

## Protocol terms

### AMP — Aegis Message Protocol
The protocol Aegis implements. Wire definitions live in
[`aegis-spec/`](../../aegis-spec/). See
[RFC-0001](../../aegis-spec/rfcs/RFC-0001-aegis-message-protocol-overview.md)
for the overview.

### Envelope
The outer object the relay sees and stores. Contains routing fields
(recipient_id, sender_hint, suite_id, used_prekey_ids), an opaque
encrypted payload, and outer signatures. Does **not** contain any
plaintext.

See
[RFC-0003](../../aegis-spec/rfcs/RFC-0003-envelopes-and-private-payloads.md)
for the full schema.

### PrivatePayload
The inner content of an envelope — the part that's encrypted. Carries
private headers (subject, thread_id, in_reply_to), the message body,
attachments, and extensions.

Only the recipient (with their private key + any claimed one-time
prekey secret) can decrypt this.

### IdentityDocument
A self-certifying record describing one identity. Carries the
canonical `identity_id` (a `amp:did:key:*` string), aliases,
public signing keys, public encryption keys, supported suites,
relay endpoints, and a self-signature over the whole document.

"Self-certifying" means: the document is signed by its own keys.
A verifier checks the signature **before** trusting any field —
including the identity_id, which is derived from the public keys.

See
[RFC-0002](../../aegis-spec/rfcs/RFC-0002-identity-documents-and-addressing.md).

### PrekeyBundle
A signed collection of one-time prekeys that a recipient publishes to
their relay so senders can claim them atomically. Each prekey is a
single-use Kyber768 key pair; consumption of a prekey provides
per-message forward secrecy after the recipient deletes the secret
locally.

Send-side flow: `aegit msg seal --relay <url>` claims one from the
relay, encrypts to it, stamps `Envelope.used_prekey_ids` with the
claimed `key_id`.

Recipient flow: `aegit id publish-prekeys` generates + signs a bundle
and POSTs it to `/v1/identities/:id/prekeys`.

See
[RFC-0003 §12](../../aegis-spec/rfcs/RFC-0003-envelopes-and-private-payloads.md).

### Suite
A named cryptographic construction. Identified by a stable string
like `AMP-HYBRID-X25519-MLKEM768-ED25519-MLDSA65-V1`. Wire format
specifies which KEM, which signature algorithm(s), which AEAD,
and the canonical signed-bytes encoding.

See
[RFC-0005](../../aegis-spec/rfcs/RFC-0005-cryptographic-suite-registry.md)
for the suite registry.

### Demo Suite
The local-development passphrase-keyed suite
`AMP-DEMO-XCHACHA20POLY1305`. **Not production-grade.** Exists so
contributors can run end-to-end flows without provisioning
real identity material. Has no forward secrecy, no sender
authenticity, no recipient binding.

---

## Identity terms

### `amp:did:key:*`
The canonical form of an Aegis identity_id. Derives the identity
string from the public-key material so the identifier is
self-certifying. Format follows the [W3C DID method `did:key`](https://w3c-ccg.github.io/did-method-key/)
convention with the `amp:` prefix.

Example: `amp:did:key:z6MkAlice...`

### Alias
A human-readable label attached to an identity (e.g.
`alice@example.com`). Aliases are **non-authoritative hints** at the
protocol layer — the relay vouches for the alias → identity_id mapping
only for domains it has claimed (see Domain Claim).

### Domain Claim
The operator-side proof that a relay is authorized to serve aliases
for a domain. The operator sets a DNS TXT record at
`_aegis-verify.<domain>` with a server-issued token; the relay
verifies the record before activating alias gating for that domain.

After a domain is claimed and verified, the relay enforces a strict
mapping: only the operator can provision `*@<domain>` aliases.

See
[RFC-0004](../../aegis-spec/rfcs/RFC-0004-relay-api.md) for the
endpoint contract.

### Resolver
The mechanism for looking up an identity given an identifier. In v0.3-alpha:

- **In code**: `aegis_identity::resolver::Resolver` trait, with
  `HttpResolver` (production) and `StaticResolver` (test) impls.
- **On the wire**: relay endpoints `GET /v1/identities/:id`,
  `GET /v1/aliases/:alias`.
- **In bootstrap**: discovery doc at `/.well-known/aegis-config`
  (see [RFC-0007](../../aegis-spec/rfcs/RFC-0007-client-discovery.md)).

There is **no central resolver service** and no key-transparency log
yet.

### Self-certifying
A property of identity documents and identifiers: the binding between
identifier and key material is enforced by cryptography rather than
by trust in a registry. To trust an `IdentityDocument`, verify its
self-signature; the identity_id is then bound to that key material
by derivation, not by external attestation.

---

## Relay terms

### Relay
A zero-trust store-and-forward server. Accepts opaque ciphertext
envelopes addressed to a recipient, stores them in SQLite, lets the
recipient fetch + acknowledge + delete them. Never holds payload
decryption keys.

A relay also serves identity / alias resolution, prekey publish /
claim, the discovery doc, and federation (Phase 5/6).

See [relay-operator-guide.md](./relay-operator-guide.md) for the
operational view and
[RFC-0004](../../aegis-spec/rfcs/RFC-0004-relay-api.md) for the
endpoint contract.

### Lifecycle endpoints
The relay endpoints that move an envelope through its life: push
(POST), fetch (GET), ack (POST .../ack), delete (DELETE), and cleanup
(POST /v1/cleanup). Distinct from identity / discovery / federation
surfaces; gated separately by the `LifecycleChange` token scope.

### Retention policy
Operator-configured rules for when the relay's cleanup sweep purges
envelopes. Controlled by `AEGIS_RELAY_MAX_MESSAGE_AGE_DAYS` (hard age
limit) and `AEGIS_RELAY_PURGE_ACKED_ON_CLEANUP` (also remove acked
envelopes on sweep).

### Federation
Phase 5/6 cross-relay delivery. When the recipient's
`IdentityDocument` lists a `relay_endpoints` URL that isn't the
sender's local relay, the sender's relay pushes the envelope to the
recipient's relay via the same `POST /v1/envelopes` endpoint.

Phase 6 adds **mutual relay authentication**: signed delivery
receipts (recipient relay signs an ack with its own `relay_identity`
keys; sender relay verifies), optional trusted-peer allowlist via
`AEGIS_FEDERATION_TRUSTED_PEERS`, and optional sender-side mTLS via
`AEGIS_FEDERATION_CLIENT_CERT_PATH` / `_KEY_PATH` / `_CA_BUNDLE_PATH`.

### Audit Log
JSONL stream of structured events written by the relay for every
write-path operation: envelope store, identity put, prekey publish,
prekey claim, ack, delete, cleanup. Configure with
`AEGIS_RELAY_AUDIT_LOG_PATH`.

---

## Gateway terms

### Gateway
The legacy SMTP/IMAP boundary. **Outside trusted core** — plaintext
crosses the gateway by definition because it bridges legacy email
into Aegis envelopes (and back).

See [RFC-0006](../../aegis-spec/rfcs/RFC-0006-gateway-and-downgrade-boundary.md)
and [aegis-gateway/docs/smtp-imap-adapter.md](../../aegis-gateway/docs/smtp-imap-adapter.md).

### Downgrade
Any flow that reduces AMP-native protections while interacting with
non-AMP systems. The gateway is the canonical downgrade boundary —
sealing legacy plaintext into envelopes (ingress) or unsealing
envelopes for delivery to legacy MTAs (egress) both qualify.

### Downgrade Policy
Operator-configured rules for how the gateway treats outbound
downgrades. Modes: `Reject` (block), `AllowWithWarning` (proceed +
emit warning), `RequireUserConfirmation` (proceed only if the
`X-Aegis-Downgrade-Confirmed: true` header is present).

### Downgrade Audit Event
Typed JSON event emitted by the gateway for every downgrade
evaluation. Captures timestamp, decision kind, source suite,
destination classification, policy snapshot, and a human-readable
reason. Defined in `aegis-gateway/src/audit.rs::DowngradeAuditEvent`.

---

## Cryptography terms

### PQ / Post-Quantum
Cryptographic algorithms believed to resist attacks by quantum
computers. Aegis uses **hybrid PQ**: classical algorithm + PQ
algorithm combined so the message is secure if either half remains
unbroken.

### Hybrid PQ Suite
The production suite
`AMP-HYBRID-X25519-MLKEM768-ED25519-MLDSA65-V1`:

- **KEM**: X25519 ECDH + ML-KEM-768 (NIST FIPS 203), HKDF-SHA256
  combine, XChaCha20-Poly1305 AEAD.
- **Signatures**: Ed25519 + ML-DSA-65 (Dilithium3, NIST FIPS 204).
  Both signatures present on production envelopes; clients verify
  per their configured signature policy.

### ML-KEM-768
NIST FIPS 203 finalized lattice-based KEM (formerly Kyber768).
Provides ~NIST Level 3 PQ security. Used as the PQ half of the
hybrid KEM. Encapsulation key is 1184 bytes; decapsulation key
is a 64-byte seed in v0.3.0-alpha.

### ML-DSA-65
NIST FIPS 204 finalized lattice-based signature scheme (formerly
Dilithium3). Provides ~NIST Level 3 PQ security. Used as the PQ
half of the hybrid signature. Public key is 1952 bytes; signing
key is a 32-byte seed in v0.3.0-alpha.

### KEM — Key Encapsulation Mechanism
An asymmetric primitive that lets a sender derive a shared secret
with a recipient using only the recipient's public key. The
recipient decapsulates with their private key. KEMs are the
PQ-friendly analogue of Diffie-Hellman.

### AEAD
Authenticated Encryption with Associated Data. The symmetric primitive
that takes a key + nonce + associated data + plaintext and returns
authenticated ciphertext. Aegis uses XChaCha20-Poly1305.

### Forward Secrecy
A property where compromise of long-term keys does not let an
adversary decrypt past traffic. In Aegis, achieved per-message by:

1. Recipient publishing one-time prekeys.
2. Sender claiming one atomically + using it in the hybrid KEM combine.
3. Relay enforcing single-use of each `key_id` via `used_prekey_ids`.
4. Recipient deleting the consumed prekey secret after successful
   AEAD-verified decrypt.

Long-term-key forward secrecy is still partial in v0.3-alpha — see
[security-faq.md](./security-faq.md).

### Signature Policy
Client-side configuration for how to combine the classical and PQ
signature verification results. Modes: `None` (skip verification),
`BestEffort` (default; tolerate absence, reject present-but-failed),
`RequireClassical`, `RequirePq`, `RequireBoth`.

Lives in `aegis_crypto::signature_policy`; CLI flag is
`aegit msg open --signature-policy <mode>`.

### Experimental PQ
Feature-gated trait-shape sandbox in
`aegis_crypto::experimental_pq` for future PQ algorithms (Falcon,
SPHINCS+, etc.). Gated behind the `experimental-pq` Cargo feature;
not enabled by default. Algorithm labels encode "EXPERIMENTAL" so
they cannot be confused with registered suites.

---

## Related documents

- [contributor-quickstart.md](./contributor-quickstart.md) — fresh-checkout setup
- [architecture-overview.md](./architecture-overview.md) — system structure
- [security-model.md](./security-model.md) — what's shipped vs not
- [security-faq.md](./security-faq.md) — humans-language security Q&A
- [relay-operator-guide.md](./relay-operator-guide.md) — relay ops
- [RFC index](../../aegis-spec/docs/protocol-index.md) — active RFCs
