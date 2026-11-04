#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
response=$(mktemp "${TMPDIR:-/tmp}/dsp-e2e-response.XXXXXX")
trap 'rm -f "$response"' EXIT

curl --fail --silent --show-error --max-time 15 \
  -H 'Content-Type: application/json' \
  --data-binary "@$script_dir/request.json" \
  http://127.0.0.1:9800/prebid/bid > "$response"

jq -e '
  .id == "dsp-e2e-auction" and .cur == "USD" and
  (.seatbid[0].bid[0] |
    .price == 2 and .crid == "1.1.1" and .w == 300 and .h == 250 and
    (.adm | contains("DSP E2E banner") and contains("http://10.0.2.2:8000/prebid/click")))
' "$response" > /dev/null

echo "Local DSP returned the synthetic 300x250 banner bid."
