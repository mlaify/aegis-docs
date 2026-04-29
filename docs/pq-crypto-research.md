# PQ Crypto Research (Pre-Implementation)

Status: Informational (non-normative)

This note compares candidate Rust-compatible post-quantum crates before selecting a real experimental dependency for Aegis.

## Scope

- Current state: `experimental-pq` is a placeholder boundary in `aegis-crypto`.
- Goal of this note: support the next decision to integrate one real KEM under feature flag.
- Non-goal: production PQ rollout.

## Candidate Comparison

| Candidate | Standards alignment | Maintenance posture | Pure Rust vs FFI | API ergonomics | Feature-gating impact | Experimental suitability | Future production suitability |
|---|---|---|---|---|---|---|---|
| `ml-kem` | High (ML-KEM naming and direction) | Appears active in current ecosystem snapshots | Pure Rust | Focused and relatively direct KEM API shape | Low-to-moderate; scoped crate | High | Medium-high, pending sustained maintenance review |
| `fips203` | High (explicit FIPS 203 framing) | Appears active and standards-oriented | Pure Rust (plus optional FFI companion crate exists separately) | Standards-forward API, may be slightly more formal | Low-to-moderate; can stay behind feature | High | High candidate for production track if maturity continues |
| `pqcrypto-kyber` | Medium-high (Kyber family lineage; pre-standard naming) | Historically common in Rust PQ experiments | Often tied to broader `pqcrypto` ecosystem and backend assumptions | Usable, but packaging/backends can be heavier | Moderate; may pull wider dependency surface | Medium-high | Medium; possible migration friction vs FIPS/ML-KEM naming |
| `rustpq` (already identified) | Broad PQ suite focus | Less clear long-term posture for Aegis use | Pure Rust | Broad API surface; more than needed for first KEM step | Moderate-to-high due to larger scope | Medium | Medium; larger surface increases review burden |

## Recommendation (Current)

1. Keep placeholder `experimental-pq` boundary for deterministic boundary tests.
2. Integrate one real KEM experimentally behind the same feature flag.
3. Current experimental integration choice: `pqcrypto-kyber` (`kyber768`) for minimal API bring-up.
4. Keep integration minimal:
   - one wrapper type behind `experimental-pq`
   - compile- and test-time coverage only
   - no CLI/relay default path change

## Experimental Result (Current Workspace)

- Implemented `ExperimentalKyber768Kem` in `aegis-core/crates/aegis-crypto/src/experimental_pq.rs`.
- Added feature-gated round-trip tests for:
  - keypair generation
  - encapsulate/decapsulate
  - invalid key material handling
- Default build remains unchanged; experimental code only compiles/runs with `--features experimental-pq`.

## Decision Inputs Still Needed Before Production Consideration

- Security review depth and update cadence over time.
- Interop expectations with future hybrid key-agreement design.
- Performance and memory behavior in target environments.
- Clarity on key serialization expectations for future protocol extensions.

## Explicit Non-Decision

- Aegis does **not** claim production PQ support in v0.1.
- No wire-format changes are implied by this research note.
