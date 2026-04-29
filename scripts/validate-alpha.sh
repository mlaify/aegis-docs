#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

section() {
  printf '\n==> %s\n' "$1"
}

run_repo_checks() {
  repo="$1"
  section "$repo: fmt/clippy/test"
  cd "$ROOT_DIR/$repo"
  cargo fmt --check
  cargo clippy --workspace --all-targets -- -D warnings
  cargo test
}

section "aegis-core: workspace checks"
cd "$ROOT_DIR/aegis-core"
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace

section "aegis-core: experimental PQ checks"
cargo test -p aegis-crypto --features experimental-pq

run_repo_checks "aegit-cli"
run_repo_checks "aegis-relay"

section "aegis-sdk (rust): checks"
cd "$ROOT_DIR/aegis-sdk/rust"
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test

section "aegis-gateway: checks"
cd "$ROOT_DIR/aegis-gateway"
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test

section "aegis-spec: schema parse check"
cd "$ROOT_DIR/aegis-spec"
python3 - <<'PY'
import json
from pathlib import Path

schema_dir = Path("schemas")
if not schema_dir.exists():
    raise SystemExit("schemas directory not found")

for path in sorted(schema_dir.glob("*.json")):
    with path.open("r", encoding="utf-8") as f:
        json.load(f)
    print(f"ok: {path}")
PY

section "local E2E smoke test"
cd "$ROOT_DIR"
sh aegit-cli/scripts/local-e2e-demo.sh

section "alpha validation complete"
