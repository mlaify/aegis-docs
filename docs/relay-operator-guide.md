# Relay Operator Guide

Concise run-guide for operating a development or self-hosted Aegis relay.
Covers the lifecycle flows (push / fetch / ack / delete / cleanup),
local-dev token semantics, and the most common operational verbs.

Production SRE runbooks are explicitly **out of scope** for this guide —
see [release-runbook.md](./release-runbook.md) for the release process
and the `aegis-deploy` repo for the production-shaped Docker Compose
stack (Cloudflare Tunnel, Mac Mini self-hosted runner, etc.).

Normative endpoint contract: [RFC-0004 — Relay API](../../aegis-spec/rfcs/RFC-0004-relay-api.md).

---

## 1. What an Aegis relay does

A relay is a **zero-trust store-and-forward** server. It accepts opaque
ciphertext envelopes addressed to a recipient, stores them, and lets the
recipient fetch + acknowledge + delete them. It never holds payload
keys.

In v0.3.0-alpha a single relay binary also:

- Serves identity / alias resolution (`PUT/GET /v1/identities/:id`,
  `GET /v1/aliases/:alias`)
- Publishes one-time prekeys for forward-secret send-side flows
  (`POST /v1/identities/:id/prekeys`, `GET /v1/identities/:id/prekey`)
- Serves the discovery doc at `/.well-known/aegis-config`
  (see [RFC-0007](../../aegis-spec/rfcs/RFC-0007-client-discovery.md))
- Federates to peer relays for cross-org delivery (Phase 5/6)
- Optionally exposes Prometheus metrics at `/metrics`

This guide focuses on the **lifecycle endpoints** — the in/out flow
of envelopes. For the federation and discovery surfaces, see the
referenced RFCs.

---

## 2. The five lifecycle endpoints

| Verb | Endpoint | Purpose | Token scope |
|---|---|---|---|
| Push | `POST /v1/envelopes` | Sender stores an envelope addressed to a recipient | `PushEnvelope` (when token-gated) |
| Fetch | `GET /v1/envelopes/:recipient_id` | Recipient reads all undelivered envelopes for their identity | none (relay does not authenticate recipients in v0.1; this is by design — opaque ciphertext is its own access control) |
| Ack | `POST /v1/envelopes/:recipient_id/:envelope_id/ack` | Recipient marks an envelope acknowledged so retention policy can apply | `LifecycleChange` |
| Delete | `DELETE /v1/envelopes/:recipient_id/:envelope_id` | Recipient destructively removes a single envelope | `LifecycleChange` |
| Cleanup | `POST /v1/cleanup` | Operator-driven sweep using the relay's retention policy | `LifecycleChange` |

Push and Fetch are the message-pump; Ack/Delete/Cleanup are the
lifecycle. Treat them as separate concerns when reasoning about
authorization and ops.

---

## 3. Local-dev token-gated lifecycle

By default the relay's lifecycle endpoints run **open** (no token
required). Real deployments turn on per-scope token gating:

```sh
# Set tokens (comma-separated; each one is independent)
AEGIS_RELAY_AUTH_TOKENS=tok-push-only,tok-lifecycle,tok-identity-write

# Per-endpoint enforcement
AEGIS_RELAY_REQUIRE_TOKEN_FOR_PUSH=true
AEGIS_RELAY_REQUIRE_TOKEN_FOR_IDENTITY_PUT=true
```

Each token carries scopes (`PushEnvelope` / `IdentityWrite` /
`LifecycleChange`) configured via the admin API or runtime config.

**Caveats:**

- Tokens are bearer credentials. Any party with the token can replay
  it. Rotate via the admin endpoints, don't pin in source control.
- The `--token` flag on `aegit` is for local-dev convenience.
  Production callers should use the config-file fallback documented
  in [aegit-cli README](../../aegit-cli/README.md#configuration) or
  set `AEGIS_RELAY_TOKEN` in their environment.
- A 403 from the relay means the token's scope set doesn't include
  the operation, not that the token is invalid. Add the right scope
  via `POST /admin/tokens` or revoke and re-issue.

For the admin-side endpoints (`/admin/*`) and federation surface, see
the relay's own README and the spec.

---

## 4. Push: sender → relay

```sh
# Seal an envelope locally (see aegit-cli for the full flow)
aegit msg seal --to amp:did:key:zRecipient --body "hello" \
  --passphrase demo-passphrase --out /tmp/sealed.json

# Push it
aegit relay push --input /tmp/sealed.json
# (relies on --relay flag, AEGIS_RELAY_URL, or relay = "..." in
#  ~/.aegis/aegit/config.toml)
```

Output:

```
status pushed
accepted true
id <envelope-uuid>
to amp:did:key:zRecipient
input /tmp/sealed.json
relay <relay-side-id>
```

Common failures:

| Status | What it means | Fix |
|---|---|---|
| 401 | Token missing | Pass `--token`, set `AEGIS_RELAY_TOKEN`, or config |
| 403 | Token lacks `PushEnvelope` scope | Add scope via admin |
| 409 `prekey_already_used` | Sender claimed a prekey id that was already consumed | Re-claim a fresh prekey via `aegit msg seal --relay ...` |
| 409 `unknown_prekey` | Sender cited a `key_id` not in the recipient's published pool | Verify the recipient's prekey publication is current |
| 413 | Envelope too large | Reduce payload or raise the relay's size limit |
| 5xx | Relay-side error | Check relay logs; retry |

---

## 5. Fetch: recipient pulls undelivered envelopes

```sh
aegit relay fetch --recipient amp:did:key:zRecipient --out /tmp/inbox/
```

Output:

```
status fetched
count 3
recipient amp:did:key:zRecipient
dir /tmp/inbox/
/tmp/inbox/<envelope-id-1>.json
/tmp/inbox/<envelope-id-2>.json
/tmp/inbox/<envelope-id-3>.json
```

Notes:

- Fetch is **non-destructive**. Envelopes remain on the relay until
  ack or delete (or the cleanup sweep fires).
- A recipient who fetches but never acks accumulates state on the
  relay — see §7 (retention) for how the cleanup policy reclaims.
- There is no relay-side authentication of recipients in v0.1. Any
  party who knows a recipient identity ID can fetch their envelopes
  (which are still opaque ciphertext to anyone without the
  recipient's private keys). Future work: per-recipient lifecycle
  tokens.

---

## 6. Ack and delete: recipient lifecycle transitions

```sh
# Mark an envelope acknowledged (relay can apply retention policy later)
aegit relay ack \
  --recipient amp:did:key:zRecipient \
  --envelope-id <uuid>

# Destructively delete a single envelope
aegit relay delete \
  --recipient amp:did:key:zRecipient \
  --envelope-id <uuid>
```

Both emit:

```
status acknowledged   # or deleted
recipient amp:did:key:zRecipient
id <uuid>
```

Use-cases:

- **Ack** is the lifecycle nudge for "I've processed this; the relay
  may apply retention to it." It does not free storage until the
  retention sweep fires (see §7).
- **Delete** is destructive and immediate. Use when you know you
  don't need an envelope on the relay anymore — e.g., after the
  client has its own durable copy.

Common failures (404 in particular):

- `404` on ack/delete: envelope already acked or deleted, or recipient
  ID is wrong. The CLI's `hint:` line distinguishes these cases.
- `403` on ack/delete: token lacks `LifecycleChange` scope.

---

## 7. Cleanup: relay-side retention sweep

The cleanup endpoint runs the relay's retention policy and reports
three counters:

```sh
aegit relay cleanup
```

```
status cleaned
expired_removed 2
orphan_ack_removed 0
old_removed 5
```

Meaning:

| Counter | Removed when |
|---|---|
| `expired_removed` | An envelope's `expires_at` is in the past |
| `orphan_ack_removed` | An ack record exists with no matching envelope |
| `old_removed` | An envelope's `created_at` is older than `AEGIS_RELAY_MAX_MESSAGE_AGE_DAYS` (when set) |

Operator knobs:

```sh
# Set a hard age limit; envelopes older than this are removed on cleanup.
AEGIS_RELAY_MAX_MESSAGE_AGE_DAYS=30

# When true, acknowledged envelopes are also purged on cleanup.
AEGIS_RELAY_PURGE_ACKED_ON_CLEANUP=true
```

Run cleanup as a periodic cron from outside the relay (the relay does
not run its own scheduler). A daily run is a reasonable starting
cadence for production-shaped deployments.

---

## 8. Operator workflow: typical day

1. **Monitor** — `GET /v1/status` returns envelope counts and auth
   posture. Hook this into your dashboard. The relay also serves
   federation-specific counters at `GET /admin/federation/metrics`
   and (when enabled) Prometheus text at `GET /metrics` —
   gate at the network edge.
2. **Audit** — `GET /admin/audit` returns the structured JSONL audit
   log (envelope writes, identity puts, lifecycle changes,
   prekey publishes / claims). Configure the file path with
   `AEGIS_RELAY_AUDIT_LOG_PATH`.
3. **Cleanup** — Daily cron: `aegit relay cleanup` (or direct
   `POST /v1/cleanup`). Check the three counters; an unbounded
   `old_removed` indicates the age limit is doing its job and the
   relay is not accumulating stale state.
4. **Token rotation** — When rotating a deployment's tokens, mint
   the new one via `POST /admin/tokens` before revoking the old via
   `DELETE /admin/tokens/:index`. Tokens are revocable; identity
   keys are not.
5. **Storage** — The relay uses SQLite WAL (`storage.rs`). Back up
   the DB file with the WAL/SHM siblings. The relay tolerates being
   killed mid-write (WAL handles atomicity); don't `rm` the SQLite
   file from under a running relay.

---

## 9. Things this guide does NOT cover

- **Production SRE runbooks** — TLS termination details, monitoring
  alert thresholds, DR plans, capacity planning. See `aegis-deploy`.
- **Federation operator runbook** — how to set up `AEGIS_FEDERATION_*`
  env vars, trusted-peer allowlists, mTLS in-flight. See
  `aegis-deploy/.env.example` and the relay's CHANGELOG.
- **Gateway operator runbook** — legacy SMTP/IMAP boundary specifics.
  See `aegis-gateway/docs/smtp-imap-adapter.md`.
- **Admin UI usage** — the operator console in `aegis-admin`. See
  that repo's README.

---

## 10. References

- [RFC-0004 — Relay API](../../aegis-spec/rfcs/RFC-0004-relay-api.md) (normative endpoints)
- [release-runbook.md](./release-runbook.md) (release process)
- [local-development.md](./local-development.md) (dev loop)
- [security-faq.md](./security-faq.md) (trust model)
- [aegit-cli/README.md](../../aegit-cli/README.md) (CLI configuration + flags)
- [aegis-deploy/.env.example](../../aegis-deploy/.env.example) (full env-var inventory for production-shaped deployments)
