# Aegis Threat Model

## Scope and Version

This threat model describes the current Aegis `v0.1` draft implementation and explicitly calls out future protections that are not yet active.

Aegis today is a reference secure asynchronous messaging stack with:

- encrypted private payloads in relay-visible envelopes,
- local CLI seal/open workflows,
- a local HTTP relay with file-backed storage.

It is not a finished production security system yet.

## Security Posture Summary

- Aegis assumes endpoints are more trusted than infrastructure.
- Relays are treated as honest-but-curious store-and-forward systems.
- Private content confidentiality is prioritized over metadata privacy.
- Several authenticity and key-lifecycle protections are planned but not yet enforced.

---

## 1. What Aegis Protects Against

### 1.1 Passive interception

Current protection:

- `PrivatePayload` is encrypted before relay submission.
- Interceptors on the network path and relay operators do not need plaintext access to transport/store envelopes.

Important caveat:

- This statement applies to payload confidentiality only, not full metadata secrecy.
- Current crypto suite in local flow is a demo suite, not a final production-hardening claim.

### 1.2 Relay compromise

Current protection:

- Relay compromise does not automatically expose plaintext message bodies, because relays store encrypted payload blobs.

What still leaks under relay compromise:

- Envelope metadata (recipient identifier, timestamps, content type, suite id, optional sender hint).
- Traffic patterns and volume visible at relay boundary.

### 1.3 Metadata leakage (partial)

Current protection:

- Aegis keeps private headers/body encrypted inside payload ciphertext.

What remains exposed by design in v0.1:

- Routing/storage metadata carried by `Envelope`.
- Fetch timing and recipient-query patterns at relay API.

So: Aegis reduces metadata exposure relative to plaintext mail content, but does not provide strong metadata-hiding guarantees.

### 1.4 Impersonation (future with signatures)

Current reality:

- Full sender authenticity enforcement via verified signatures is not implemented.
- `outer_signature_b64` exists in the model but is not enforced in runtime.

Future direction:

- Identity-document and envelope signature verification are expected to provide stronger anti-impersonation guarantees once implemented.

---

## 2. What Aegis Partially Protects

### 2.1 Traffic analysis

Partial protection only:

- Message content is encrypted, so simple content inspection is blocked.
- But envelope metadata, relay endpoints, and recipient-scoped fetches still expose analyzable patterns.

Result:

- A local or regional observer has meaningful traffic-analysis surface.
- Aegis v0.1 does not claim resistance to sophisticated traffic analysis.

### 2.2 Timing correlation

Partial protection only:

- Asynchronous store-and-forward can decouple sender and recipient online time somewhat.
- But push/fetch timing remains observable at relay and network boundaries.

Result:

- Timing correlation is harder than direct synchronous messaging in some cases, but far from solved.

---

## 3. What Aegis Does NOT Yet Protect

### 3.1 Global adversary correlation

Not protected in v0.1:

- A global passive adversary observing many network segments can correlate sender/relay/recipient activity.
- Aegis does not currently provide anonymity-network style protection.

### 3.2 Coercion attacks

Not protected in v0.1:

- Aegis does not provide deniability protocols, coercion-resistant key disclosure controls, or advanced legal-compulsion mitigations.
- Stored ciphertext and endpoint state remain coercion targets.

### 3.3 Compromised endpoints

Not protected in v0.1:

- If sender or recipient device is compromised, message confidentiality/integrity can fail regardless of relay design.
- Aegis does not yet include endpoint hardening, secure enclave policy enforcement, or malware-resilience guarantees.

---

## 4. Trust Boundaries

### 4.1 Client boundary

Trust level: highest in current architecture.

Client responsibilities:

- Hold secrets.
- Seal and open payloads.
- Apply identity and trust policy.

Failure impact:

- Client compromise is catastrophic for confidentiality and authenticity.

### 4.2 Relay boundary

Trust level: explicitly low.

Relay responsibilities:

- Accept, persist, and return envelopes.
- Provide availability of stored ciphertext objects.

Relay non-responsibilities (by design):

- Plaintext access.
- Security truth for sender identity.
- Cryptographic trust decisions.

### 4.3 Gateway boundary

Trust level: constrained and high-risk boundary.

Gateway role:

- Handle interoperability with legacy email ecosystems outside Aegis core.

Risk:

- Gateway is where downgrade pressure and compatibility tradeoffs appear.
- In v0.1, gateway hardening is incomplete; this boundary should be treated as sensitive.

---

## 5. Security Assumptions

Aegis currently relies on these assumptions:

### 5.1 Endpoints are trusted

- Sender and recipient execution environments are assumed uncompromised enough to manage keys and plaintext.
- If this assumption fails, most protocol-layer protections collapse.

### 5.2 Cryptography is correctly implemented

- Implementations are assumed free of critical crypto misuse and major implementation flaws.
- In v0.1, this is a development-stage assumption, not a formally validated assurance.

### 5.3 Relay is honest-but-curious

- Relay is assumed to follow basic store/fetch protocol behavior.
- Relay is not assumed to protect confidentiality beyond forwarding ciphertext.
- Relay may observe metadata and attempt correlation.

---

## Current vs Future Control Matrix

### Implemented now

- Payload encryption before relay submission.
- Opaque payload handling at relay.
- Identity-addressing direction (`amp:did:key:...`) with alias de-prioritization.

### Not fully implemented yet

- End-to-end signature verification for strong anti-impersonation.
- Enforced prekey lifecycle and forward-secrecy properties.
- Relay authn/authz and stronger anti-abuse controls.
- Metadata-minimization techniques beyond current envelope model.

---

## Bottom Line

Aegis `v0.1` provides meaningful protection of message content against relay and network plaintext exposure, but it does not yet provide complete authenticity guarantees, strong metadata privacy, or endpoint-compromise resilience.

That is intentional at this stage: confidentiality-first reference architecture now, with authenticity hardening, key lifecycle enforcement, and broader adversary resistance in future phases.
