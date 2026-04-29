# v0.1.0-alpha Release Runbook

This runbook defines pre-tag checks for an Aegis `v0.1.0-alpha` checkpoint.

## Preconditions

- All release-scope repos are on intended branch and up to date.
- No unresolved protocol/schema/RFC mismatches.
- Local Rust toolchain available.

## Required Pre-Release Checks

From workspace root:

```sh
sh aegis-docs/scripts/validate-alpha.sh
```

The script runs:

- `cargo fmt --check` where applicable
- `cargo clippy --workspace --all-targets -- -D warnings` where applicable
- `cargo test` where applicable
- `cargo test -p aegis-crypto --features experimental-pq`
- schema JSON parse checks in `aegis-spec`
- local E2E smoke test `sh aegit-cli/scripts/local-e2e-demo.sh`

## Manual Review Before Tag

- Confirm README status language still reflects draft/prototype alpha.
- Confirm no production PQ/resolver/gateway claims were introduced.
- Confirm conformance doc reflects current implementation.

## Tag Naming Convention

- Alpha tags: `v0.1.0-alpha` (and optional incrementing suffixes such as `v0.1.0-alpha.1`).
- Do not use stable semver tags until production readiness criteria are explicitly defined.

## Post-Tag Notes

- Capture known limitations in release notes.
- Keep alpha caveats visible in README/SECURITY docs.
