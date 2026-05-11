# Security FAQ

Common questions about Aegis's security posture as of v0.3.0-alpha.
Normative claims live in the RFCs; this page summarizes for humans.

For the structured threat model and what's currently shipped, see
[security-model.md](./security-model.md). For vulnerability disclosure,
see the repo's [SECURITY.md](../SECURITY.md).

---

## Trust boundaries

### Is the relay trusted?

**No.** Relays are explicitly **zero-trust** for plaintext content. The
relay's job is store-and-forward of opaque ciphertext envelopes; it
never holds payload decryption keys.

What the relay can do (operator-observable):

- See envelope metadata: recipient identity, sender hint, timestamps,
  envelope size, suite identifier.
- See traffic patterns (when, how often, what size).
- Refuse to deliver, alter ordering, lie about whether something was
  acknowledged.

What the relay cannot do (cryptographically prevented):

- Decrypt payloads.
- Forge envelope signatures.
- Modify a stored envelope without detection (signatures cover the
  outer envelope).

Normative spec: [RFC-0004 §3](../../aegis-spec/rfcs/RFC-0004-relay-api.md).

### Is the gateway trusted?

**No.** Gateway is explicitly **outside the trusted core** — it bridges
legacy email (SMTP/IMAP) into Aegis envelopes and back, which means
plaintext crosses the gateway boundary. A compromised gateway operator
sees plaintext of every legacy-bridged message.

The gateway is a deliberate downgrade boundary. See
[RFC-0006](../../aegis-spec/rfcs/RFC-0006-gateway-and-downgrade-boundary.md)
for the model and [aegis-gateway/docs/smtp-imap-adapter.md](../../aegis-gateway/docs/smtp-imap-adapter.md)
for the implementation design.

### Is the discovery endpoint trusted?

**TLS is the trust anchor.** `GET /.well-known/aegis-config` is
unauthenticated at the Aegis layer; the standard PKI trust roots that
authenticate the TLS handshake are what attests to the discovery
document.

A manipulated discovery channel can redirect clients to an
attacker-controlled relay or substitute a malicious `relay_identity`.
Use HTTPS with standard CAs.

Normative spec:
[RFC-0007 §9](../../aegis-spec/rfcs/RFC-0007-client-discovery.md).

---

## Cryptography status

### Is the demo suite production-grade?

**No.** `AMP-DEMO-XCHACHA20POLY1305` is a passphrase-keyed local-dev
suite. It exists so contributors can run end-to-end flows without
provisioning real identity material. Anything sealed with it has no
forward secrecy, no sender authenticity, no recipient binding.

Do not use it for anything that needs cryptographic security.

### Is the production suite post-quantum?

**Yes** — `AMP-HYBRID-X25519-MLKEM768-ED25519-MLDSA65-V1` is the
shipped production suite. Hybrid means both classical and PQ halves
must be broken to compromise a message:

- **KEM**: X25519 ECDH + ML-KEM-768 (NIST FIPS 203). HKDF-SHA256
  combine; XChaCha20-Poly1305 AEAD.
- **Signatures**: Ed25519 + ML-DSA-65 (Dilithium3, NIST FIPS 204).
  Both must verify under
  the default `BestEffort` signature policy; stricter modes
  (`RequireClassical` / `RequirePq` / `RequireBoth`) are available
  to clients via `--signature-policy` on the CLI.

Normative spec:
[RFC-0005](../../aegis-spec/rfcs/RFC-0005-cryptographic-suite-registry.md).

### What's the experimental PQ feature gate?

A separate Cargo feature `experimental-pq` on `aegis-crypto` gates
trait-shape placeholders for future PQ algorithms (Falcon, SPHINCS+,
etc.). These are **not** production. Default builds don't include them;
turn on with `cargo --features experimental-pq`.

The placeholder algorithms (`AMP-HYBRID-PQ-PLACEHOLDER-EXPERIMENTAL`,
`AMP-EXPERIMENTAL-PQ-SIG-PLACEHOLDER`) encode "EXPERIMENTAL" in the
label so they can't be mistaken for registered suites.

### Are one-time prekeys supported?

**Yes**, as of v0.3.0-alpha. Recipients publish a pool of one-time
prekeys via `POST /v1/identities/:id/prekeys`; senders claim them
atomically via `GET /v1/identities/:id/prekey` and stamp the
`key_id` into `Envelope.used_prekey_ids` so the relay can reject
replay.

Forward secrecy: the recipient deletes the consumed prekey-secret
locally after a successful AEAD-verified decrypt. Replay of the
ciphertext won't decrypt; replay of an envelope with the same
`key_id` is rejected at the relay.

Normative spec:
[RFC-0003 §12](../../aegis-spec/rfcs/RFC-0003-envelopes-and-private-payloads.md).

---

## Identity and resolution

### How is identity established?

Cryptographic identifiers (`amp:did:key:zXXXX`) derived from public
keys. The `IdentityDocument` is self-certifying: signed by its own
Ed25519 + Dilithium3 keys. Verifiers check the signature before trusting
any field on the document.

There is **no central CA** and no production resolver service in
v0.3-alpha. Identity resolution today goes through whichever relay is
serving `user@domain`; that relay vouches for the alias → identity_id
mapping for domains it has claimed.

### How are domains "claimed"?

An operator owning `example.com` proves control by setting a DNS TXT
record at `_aegis-verify.example.com` with a server-issued token.
After verification, the relay enforces alias gating for that domain
(only the operator can provision `*@example.com` aliases).

This is **operator-side authorization**, not user-side identity. It
establishes that the relay is authorized to speak for the domain.

Normative spec: [RFC-0004](../../aegis-spec/rfcs/RFC-0004-relay-api.md)
domain claim flow.

### What if the relay lies about an alias?

If a relay returns `IdentityDocument X` for alias `alice@example.com`
but later returns `IdentityDocument Y`, clients see a binding change.
There is no cross-relay attestation in v0.3-alpha. The protection here
is:

1. The `IdentityDocument` itself is self-certifying — a malicious
   relay can only return a document the legitimate identity-holder
   signed (or substitute a different identity entirely, which the
   user sees as a key change).
2. Domain-claim authorization (above) limits which relay can serve a
   given domain's aliases.

Future work: peer-attestation / "key transparency"-style logs for
cross-relay binding consistency.

---

## What's explicitly NOT solved

- **Full metadata privacy.** Recipient identity, timing, and traffic
  patterns are observable to the relay and the network. Sealed-sender
  / mixnet-style metadata protection is not part of v0.3-alpha.
- **Production trust policy / cross-relay attestation.** See above.
- **Gateway-side downgrade safety.** Plaintext crosses the gateway
  boundary by definition. The downgrade event model (RFC-0006) makes
  policy decisions auditable but does not preserve confidentiality
  for legacy-bridged messages.
- **Long-term forward secrecy under key compromise.** Prekeys give
  per-message forward secrecy after consumption + local delete;
  long-term identity-key compromise still exposes past messages
  encrypted to that long-term key (e.g., when prekey pool was
  exhausted and senders fell back to the long-term Kyber key).

---

## Reporting issues

Security issues: **do not** open public GitHub issues. See
[SECURITY.md](../SECURITY.md) (disclose.io VDP format) for the
private disclosure channels and Safe Harbor terms.

Non-security questions about the security model: open a `docs` issue
on `aegis-docs` or a `protocol_change` issue on `aegis-spec` if the
question affects normative spec text.

---

## Further reading

- [security-model.md](./security-model.md) — structured "what's
  shipped vs not" view
- [threat-model.md](../threat-model.md) — adversary model
- [philosophy.md](../philosophy.md) — design principles
- [RFC-0001](../../aegis-spec/rfcs/RFC-0001-aegis-message-protocol-overview.md) — protocol overview
- [RFC-0004](../../aegis-spec/rfcs/RFC-0004-relay-api.md) — relay trust model + endpoints
- [RFC-0005](../../aegis-spec/rfcs/RFC-0005-cryptographic-suite-registry.md) — suite registry
- [RFC-0006](../../aegis-spec/rfcs/RFC-0006-gateway-and-downgrade-boundary.md) — gateway boundary
- [RFC-0007](../../aegis-spec/rfcs/RFC-0007-client-discovery.md) — client discovery + TLS trust
