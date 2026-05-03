# Security Model

This page summarizes current behavior. Normative security claims live in RFCs.

## What is implemented (v0.2.0-alpha)

### Confidentiality

- **Hybrid post-quantum payload encryption** (`AMP-HYBRID-X25519-MLKEM768-ED25519-MLDSA65-V1`):
  - Ephemeral X25519 ECDH for classical forward-secret KEM component
  - ML-KEM-768 (Kyber768, NIST FIPS 203) for quantum-resistant KEM component
  - Shared secrets combined via HKDF-SHA256; AEAD with XChaCha20-Poly1305
  - Security holds if *either* X25519 or ML-KEM-768 remains unbroken
- Relay remains zero-trust: stores and forwards ciphertext, never holds decryption keys
- Demo suite (`AMP-DEMO-XCHACHA20POLY1305`) retained for local development only

### Integrity and Authentication

- **Hybrid post-quantum envelope signing**:
  - Ed25519 classical signature (`outer_signature_b64`)
  - Dilithium3 / ML-DSA-65 (NIST FIPS 204) post-quantum signature (`outer_pq_signature_b64`)
  - Both signatures required and both must verify for the envelope to be considered authentic
- Canonical signed bytes exclude both signature fields to prevent circular dependencies

### Identity

- Cryptographic identity rooted in `amp:did:key:*` identifiers
- `IdentityDocument` carries four public key records for the hybrid PQ suite:
  - `AMP-X25519-V1` (32-byte classical KEM public key)
  - `AMP-MLKEM768-V1` (1184-byte PQ encapsulation key)
  - `AMP-ED25519-V1` (32-byte classical signing key)
  - `AMP-MLDSA65-V1` (1952-byte PQ verification key)
- Private key material (`HybridPqPrivateKeyMaterial`) stored separately, never transmitted

### Protocol Conformance

- Relay validates structural completeness of PQ envelopes (rejects missing KEM transport or PQ signature fields)
- Gateway policy blocks PQ envelopes to legacy destinations by default
- Suite identifier is an explicit wire field; unknown suites are rejected

## What is not yet production-ready (v0.2.0-alpha)

- Network identity resolver (lookup and trust of remote IdentityDocuments over the network)
- Prekey bundle consumption enforcement (one-time prekeys not yet enforced)
- Self-certifying IdentityDocument signatures
- Gateway SMTP/IMAP transformation (policy scaffold only)
- Relay database persistence (in-memory storage)
- Client applications (desktop, mobile, web)
- Key rotation and revocation workflows

## Threat Model Summary

| Threat | Mitigation |
|--------|-----------|
| Passive network surveillance | Payload encrypted end-to-end; relay sees only ciphertext |
| Harvest-now-decrypt-later (quantum) | ML-KEM-768 KEM + Dilithium3 signatures |
| Classical KEM break (e.g. ECDH) | ML-KEM-768 provides independent security |
| PQ KEM break (Kyber) | X25519 provides independent classical security |
| Message tampering | XChaCha20-Poly1305 AEAD; hybrid signatures on envelope |
| Suite confusion | `suite_id` explicit on every envelope; unknown suites rejected |
| Relay reading payloads | Zero-trust relay: relay never holds decryption keys |
| PQ envelopes to non-PQ destinations | Gateway policy rejects by default |

## Normative References

- `../aegis-spec/rfcs/RFC-0002-identity-documents-and-addressing.md`
- `../aegis-spec/rfcs/RFC-0003-envelopes-and-private-payloads.md`
- `../aegis-spec/rfcs/RFC-0005-cryptographic-suite-registry.md`
- `../aegis-spec/docs/implementation-conformance-v0.2.md`

## Supporting Notes

- `pq-crypto-research.md` (implementation decisions and crate selection rationale)
- `../aegis-spec/docs/adr/ADR-0001-pq-crypto-boundary.md` (original decision record)
