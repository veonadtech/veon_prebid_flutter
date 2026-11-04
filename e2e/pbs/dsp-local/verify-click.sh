#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
response=$(mktemp "${TMPDIR:-/tmp}/dsp-e2e-bid.XXXXXX")
headers=$(mktemp "${TMPDIR:-/tmp}/dsp-e2e-click.XXXXXX")
trap 'rm -f "$response" "$headers"' EXIT

curl --fail --silent --show-error --max-time 15 \
  -H 'Content-Type: application/json' \
  --data-binary "@$script_dir/request.json" \
  http://127.0.0.1:9800/prebid/bid > "$response"

click_url=$(jq -r '.seatbid[0].bid[0].adm | capture("href=\"(?<url>[^\"]+)\"").url' "$response")
click_url=${click_url/10.0.2.2/127.0.0.1}
status=$(curl --silent --show-error --max-time 15 --max-redirs 0 \
  --dump-header "$headers" --output /dev/null --write-out '%{http_code}' "$click_url")

if [[ "$status" != 302 ]]; then
  echo "Expected DSP click redirect 302, got $status" >&2
  exit 1
fi
if ! tr -d '\r' < "$headers" | grep -Eqi '^location: http://10\.0\.2\.2:8000/__e2e/landing$'; then
  echo "DSP click did not redirect to the local landing page" >&2
  exit 1
fi

echo "Local DSP click redirects to the test landing page."
