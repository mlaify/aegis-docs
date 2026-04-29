# Aegis Design Philosophy

## Premise

Email is not failing because implementations are bad. It is failing because the underlying trust model is old and structurally misaligned with modern security requirements.

Aegis starts from that premise and treats secure asynchronous messaging as a protocol problem, not a UI patch or server hardening exercise.

---

## 1. Why Email Is Fundamentally Broken

### 1.1 SMTP trust model is the wrong root of trust

SMTP-era systems inherit trust from domains, DNS, and federated operator behavior. That model made sense when interoperability mattered more than adversarial resilience.

Today, this means:

- identity is conflated with provider/domain control,
- trust is routed through infrastructure ownership,
- cross-provider behavior depends on uneven policy and hygiene.

Domain control is naming power, not cryptographic identity.

### 1.2 Metadata leakage is systemic, not incidental

Traditional email leaks routing and communication patterns by design. Even when content is protected, the who/when/where surface remains broad.

This is not a bug in one provider. It is a property of the protocol family and operational ecosystem.

### 1.3 Encryption is bolt-on, not foundational

Most email encryption approaches are optional, fragmented, and operationally brittle. Security depends on user configuration discipline and endpoint compatibility luck.

If encryption can be skipped without breaking delivery, it is not a security model. It is a best-effort feature.

---

## 2. Aegis Principles

### 2.1 Identity over domains

Aegis anchors trust in cryptographic identity continuity, not domain authority.

- Canonical identity form (`amp:did:key:...`) is the trust root.
- Aliases are convenience labels, not trust anchors.
- Provider/domain migration must not redefine who an entity is.

### 2.2 Encryption by default

Private payloads are encrypted before relay transport. Relays store and forward ciphertext envelopes.

Security-critical implication:

- plaintext access is an endpoint concern,
- infrastructure is not granted decryption privilege as part of normal operation.

### 2.3 Minimal metadata exposure

Aegis does not pretend metadata can be eliminated in v0.1. It does insist metadata should be deliberately minimized and clearly separated from private content.

- private headers/body stay encrypted,
- only routing-required envelope fields remain relay-visible,
- metadata-hiding improvements are an explicit future track, not hand-waved.

### 2.4 Protocol-first design

Aegis treats the protocol as the product.

- RFCs and schemas define semantics before broad implementation spread.
- Shared core primitives carry security-sensitive behavior.
- Client/relay/gateway surfaces are integrations of protocol contracts, not independent interpretations.

This is how security properties stay auditable over time.

### 2.5 Compatibility as a boundary, not a core feature

Legacy interoperability is real, but it is a risk surface.

Aegis isolates compatibility in a gateway boundary so downgrade and translation pressure does not contaminate core identity/message guarantees.

Compatibility exists to contain legacy constraints, not to define protocol truth.

---

## 3. Why Aegis Is Not

### 3.1 Not PGP

PGP is largely a toolset layered onto email workflows. Aegis is a protocol architecture that assumes encrypted asynchronous messaging from the start.

- Aegis does not treat secure messaging as optional add-on behavior.
- Aegis is not centered on user-managed ad hoc key exchange rituals.

### 3.2 Not a Signal clone

Signal optimizes for different constraints (notably synchronous/mobile chat assumptions and a specific service ecosystem).

Aegis focuses on asynchronous, relay-mediated, identity-first messaging with explicit protocol surfaces and transport separation.

Overlap in security intent does not make the systems equivalent.

### 3.3 Not just another email server

Aegis relay infrastructure is intentionally zero-trust with respect to plaintext. The protocol trust root is cryptographic identity, not mailbox hosting.

Calling Aegis an email server misses the point: it is a different trust architecture with different boundaries.

---

## 4. Long-Term Vision

### 4.1 Post-quantum readiness

Aegis is designed for cryptographic agility, including migration paths for post-quantum suites.

This means:

- suite evolution is a first-class protocol concern,
- transitions are planned, versioned, and auditable,
- PQ support is integrated as protocol evolution, not emergency retrofit.

### 4.2 Pluggable transports

The architecture separates message semantics from transport implementation details.

This enables:

- multiple relay and delivery backends,
- federation and alternative transport strategies,
- transport evolution without redefining identity and payload semantics.

### 4.3 Secure communication fabric

The end-state is not “better email.”

The end-state is a secure communication fabric where:

- identity continuity is cryptographic,
- confidentiality is default,
- infrastructure trust is minimized,
- compatibility with legacy systems is contained at explicit boundaries.

That is the architectural direction Aegis commits to, even when short-term implementation is still catching up.

---

## Practical Position

Aegis `v0.1` is an early implementation of this philosophy, not the finished destination. Some hard guarantees (strong authenticity enforcement, full prekey lifecycle, advanced metadata defenses) are still in progress.

The philosophy does not change because implementation is incomplete. It sets the constraints that implementation must satisfy.
