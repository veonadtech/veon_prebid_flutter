#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/dsp-bidder-checkout" >&2
  exit 2
fi

repo=$(git -C "$1" rev-parse --show-toplevel)
script_dir=$(cd "$(dirname "$0")" && pwd)
output_dir=$(cd "$script_dir/.." && pwd)/.build
mkdir -p "$output_dir"
source_dir=$(mktemp -d "${TMPDIR:-/tmp}/dsp-e2e-source.XXXXXX")
trap 'rm -rf "$source_dir"' EXIT

git -C "$repo" archive HEAD | tar -x -C "$source_dir"
patch -d "$source_dir" -p1 < "$script_dir/appconfig.patch"
patch -d "$source_dir" -p1 < "$script_dir/path.patch"
cp "$script_dir/appconfig_e2e.go" "$source_dir/appconfig/e2e.go"
cp "$script_dir/config.yaml" "$source_dir/tests/test_config.yaml"
mkdir -p "$source_dir/cmd/e2e"
cp "$script_dir/main.go" "$source_dir/cmd/e2e/main.go"

(
  cd "$source_dir"
  GOPRIVATE='github.com/veonadtech/*' \
  GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
  go build -trimpath -ldflags='-s -w' -o "$output_dir/dsp-e2e" ./cmd/e2e
)

echo "Built $output_dir/dsp-e2e from $(git -C "$repo" rev-parse --short HEAD)"
