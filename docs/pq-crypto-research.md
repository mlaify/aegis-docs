# PQ Crypto Research and Implementation Decisions

Status: Informational (non-normative)

This document records the crate selection rationale and implementation decisions made for the v0.2 hybrid post-quantum cryptographic suite. For the normative specification, see RFC-0005.

## Background

The v0.1 release included `experimental-pq`, a placeholder boundary in `aegis-crypto` with a minimal `pqcrypto-kyber` wrapper behind a feature flag. No production PQ code shipped in v0.1.

v0.2 promotes PQ encryption to production status with a full hybrid construction.

## Crate Selection

### KEM: `pqcrypto-kyber v0.8`

Already present in the workspace. Selected for v0.2 production because:
- Proven to compile correctly in the existing workspace
- Straightforward API: `keypair()`, `encapsulate()`, `decapsulate()`
- Kyber768 maps directly to ML-KEM-768 (NIST FIPS 203)
- Avoids introducing a new unknown build surface mid-release

Future consideration: migrate to `ml-kem` (RustCrypto) once it reaches a stable API, as it uses the official FIPS 203 naming and is pure Rust with no C FFI.

### Signature: `pqcrypto-dilithium v0.5`

New dep for v0.2. Selected because:
- Same `pqcrypto` ecosystem as `pqcrypto-kyber`; consistent API conventions (`keypair()`, `detached_sign()`, `verify_detached_signature()`)
- Dilithium3 maps to ML-DSA-65 (NIST FIPS 204), NIST Level 3 security
- Consistent with the pqcrypto ecosystem choice already made for KEM

Future consideration: migrate to `ml-dsa` (RustCrypto) when stable.

### Classical KEM: `x25519-dalek v2`

Industry-standard. Provides X25519 Diffie-Hellman for the classical KEM half.

### Classical Signature: `ed25519-dalek v2`

Industry-standard. Provides Ed25519 signing and verification.

### KDF: `hkdf v0.12` + `sha2 v0.10`

Standard HKDF-SHA256 implementation, used to combine X25519 and ML-KEM-768 shared secrets.

### AEAD: `chacha20poly1305` (existing)

XChaCha20-Poly1305 is unchanged from v0.1. The 24-byte nonce space is large enough to safely generate nonces randomly per message.

## Hybrid Construction Rationale

The hybrid design (`ss_x25519 ‖ ss_mlkem` → HKDF → symmetric key) provides a security property stronger than either primitive alone:

- If X25519 is broken (classically or by a quantum computer), ML-KEM-768 still protects the message.
- If Kyber768 is broken (cryptanalytic break before standardization is finalized in practice), X25519 still protects the message.

This is the standard recommendation for deploying PQ cryptography before the algorithms are fully battle-tested in production.

The HKDF nonce doubles as a commitment: both shared secrets are combined with the same nonce that governs the AEAD operation, binding KEM and encryption contexts.

## Hybrid Signature Rationale

Dual classical + PQ signatures follow the same principle. A message is authentic only if *both* signatures verify. An attacker who can forge one signature type still cannot forge the other.

## Key Material Storage

The `HybridPqPrivateKeyMaterial` JSON structure stores all four private keys in a separate file (`<id>.pq-key.json`) that is never included in the IdentityDocument and never transmitted. Public keys only appear in the IdentityDocument.

## Migration Path

The `SuiteId` field on every envelope ensures clean suite migration:
- v0.1 envelopes use `AMP-DEMO-XCHACHA20POLY1305`
- v0.2 envelopes use `AMP-HYBRID-X25519-MLKEM768-ED25519-MLDSA65-V1`
- The demo suite remains available for local development and backward compatibility testing

Recipients that do not support the hybrid PQ suite will see their IdentityDocument lack `AMP-HYBRID-X25519-MLKEM768-ED25519-MLDSA65-V1` in `supported_suites`; the CLI falls back to the demo suite in that case.

## Open Questions for Future Releases

- **Prekey bundles**: One-time prekey consumption (forward secrecy per-message) is deferred to v0.3.
- **Key rotation**: No revocation or rotation mechanism is specified yet.
- **`ml-kem` / `ml-dsa` migration**: Once RustCrypto crates stabilize, evaluate a migration from `pqcrypto-*` to avoid C FFI dependency.
- **Performance profiling**: ML-KEM-768 encapsulation keys (1184 bytes) and Dilithium3 signatures (~3293 bytes) increase message sizes. Benchmarks needed before recommending for constrained environments.
