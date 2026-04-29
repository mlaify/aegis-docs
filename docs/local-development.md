# Local Development

## Recommended Workflow

1. Run formatting.
2. Run clippy.
3. Run tests.
4. Run local E2E demo.

## Primary E2E Path

Use:

- `../aegit-cli/DEV-SETUP.md`
- `../aegit-cli/scripts/local-e2e-demo.sh`
- `release-runbook.md`
- `../aegis-docs/scripts/validate-alpha.sh`

## Suggested Checks

Core:

```sh
cd ../aegis-core
cargo fmt
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

CLI:

```sh
cd ../aegit-cli
cargo fmt
cargo clippy --workspace --all-targets -- -D warnings
cargo test
sh scripts/local-e2e-demo.sh
```

Relay:

```sh
cd ../aegis-relay
cargo fmt
cargo clippy --workspace --all-targets -- -D warnings
cargo test
```

Workspace alpha validation:

```sh
cd ..
sh aegis-docs/scripts/validate-alpha.sh
```
