# PQ Crypto Research and Implementation Decisions

Status: Informational (non-normative)

This document records the crate selection rationale and implementation decisions made for the hybrid post-quantum cryptographic suite. For the normative specification, see RFC-0005.

## Background

The v0.1 release included `experimental-pq`, a placeholder boundary in `aegis-crypto` with a minimal `pqcrypto-kyber` wrapper behind a feature flag. No production PQ code shipped in v0.1.

v0.2 promoted PQ encryption to production status with a full hybrid construction backed by the round-3 NIST submissions (`pqcrypto-kyber 0.8` / `pqcrypto-dilithium 0.5`, both sourced from PQClean's C reference implementations).

**v0.3.0-alpha completes the FIPS finalization** by replacing those round-3 implementations with the FIPS-final `ml-kem` and `ml-dsa` crates from the RustCrypto project. This brings the implementation in line with what RFC-0005 always claimed (FIPS 203 ML-KEM-768 / FIPS 204 ML-DSA-65) and unblocks wire-compatible interop with non-Rust clients (the web client uses `@noble/post-quantum`, which is FIPS-final-only).

## Crate Selection (v0.3.0-alpha onward)

### KEM: `ml-kem v0.3` (RustCrypto)

- Pure-Rust implementation of FIPS 203 final.
- API: `MlKem768::generate_keypair()`, `EncapsulationKey::encapsulate()`, `DecapsulationKey::decapsulate()` (via the `kem` trait crate).
- Decapsulation keys persist as 64-byte seeds (`Seed`); encapsulation keys are 1184-byte FIPS encodings. The seed-based persistence is a significant size reduction from round-3's ~2400-byte expanded secret keys.
- No C FFI; cleaner build surface than the `pqcrypto-*` line.
- Replaces `pqcrypto-kyber 0.8` (v0.2.0-alpha; round-3 NIST submission). **Round-3 and FIPS 203 are not byte-compatible**; published identity documents from v0.2 are not loadable by v0.3 implementations.

### Signature: `ml-dsa v0.1.0-rc.9` (RustCrypto)

- Pure-Rust implementation of FIPS 204 final.
- API: `MlDsa65::key_gen(rng)`, `SigningKey::sign(msg)`, `VerifyingKey::verify(msg, sig)` (via the `signature` trait crate).
- Signing keys persist as 32-byte seeds (`Seed`); verifying keys are 1952-byte FIPS encodings. Same size reduction story as ML-KEM.
- Replaces `pqcrypto-dilithium 0.5` (v0.2.0-alpha; round-3 NIST submission). Round-3 Dilithium signatures do NOT verify under ML-DSA-65 keys and vice versa.

### RNG plumbing note

`ml-dsa 0.1.0-rc.9` pins `rand_core 0.10` for its `key_gen()` RNG argument. The aegis-core workspace still uses `rand 0.8` (which exports `rand_core 0.6`) elsewhere, so `aegis-crypto::keygen` calls `MlDsa65::key_gen()` with `getrandom::SysRng` wrapped in `rand_core::UnwrapErr` — the same shape used in `ml-dsa`'s own README. This avoids a workspace-wide bump of `rand` to 0.9+ that would cascade to many other crates.

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

- **Prekey bundles**: ✅ Shipped in v0.3 phases 1–3 (one-time prekey consumption, atomic relay enforcement, end-to-end forward secrecy).
- **`ml-kem` / `ml-dsa` migration**: ✅ Shipped in v0.3.0-alpha (this document).
- **Key rotation**: No revocation or rotation mechanism is specified yet.
- **Performance profiling**: ML-KEM-768 encapsulation keys (1184 bytes) and ML-DSA-65 signatures (~3309 bytes) increase message sizes. Benchmarks needed before recommending for constrained environments.
- **`ml-dsa` 1.0 stable**: When `ml-dsa` graduates from `rc.x` to a stable `1.0`, drop the `getrandom::SysRng` workaround in `aegis-crypto::keygen` and feed the workspace `rand 0.9+` directly.
