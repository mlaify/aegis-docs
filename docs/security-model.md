# Security Model (v0.1 Summary)

This page summarizes current behavior. Normative security claims live in RFCs.

## What is implemented now

- payload confidentiality via endpoint encryption/decryption
- relay as untrusted store-and-forward infrastructure
- relay lifecycle controls (`ack`/`delete`/`cleanup`) with optional local-dev capability token gating
- client-side demo signature hooks (non-production)
- gateway downgrade policy groundwork (outside trusted core) with explicit decisions:
  - reject
  - allow_with_warning
  - require_user_confirmation
- separated crypto responsibilities in core traits:
  - payload cipher
  - envelope signing/verification
  - future-facing key agreement boundary

## What is not yet production-ready

- post-quantum cryptography
- `experimental-pq` in `aegis-crypto` is non-production only (placeholder boundary tests plus experimental kyber768 KEM wrapper)
- production-grade signature lifecycle and key transparency
- production network resolver service
- production key agreement/KEM workflows
- production-grade relay authentication/authorization model

## Normative References

- `../aegis-spec/rfcs/RFC-0002-identity-documents-and-addressing.md`
- `../aegis-spec/rfcs/RFC-0003-envelopes-and-private-payloads.md`
- `../aegis-spec/rfcs/RFC-0005-cryptographic-suite-registry.md`
- `../aegis-spec/docs/implementation-conformance-v0.1.md`

## Supporting Notes

- `pq-crypto-research.md` (non-normative candidate comparison and integration notes)
- `../aegis-spec/docs/adr/ADR-0001-pq-crypto-boundary.md` (decision record)
