#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
response=$(mktemp "${TMPDIR:-/tmp}/pbs-dsp-auction.XXXXXX")
trap 'rm -f "$response"' EXIT

ready_timeout_seconds=${PBS_READY_TIMEOUT_SECONDS:-90}
ready_deadline=$((SECONDS + ready_timeout_seconds))
until curl --fail --silent --max-time 2 http://127.0.0.1:8000/status > /dev/null; do
  if (( SECONDS >= ready_deadline )); then
    echo "PBS-Java did not become ready within ${ready_timeout_seconds} seconds" >&2
    exit 1
  fi
  sleep 1
done

curl --fail --silent --show-error --max-time 20 \
  -H 'Content-Type: application/json' \
  --data-binary "@$script_dir/auction-request.json" \
  http://127.0.0.1:8000/openrtb2/auction > "$response"

if ! jq -e '
  .id == "dsp-pbs-e2e-auction" and
  .seatbid[0].seat == "generic" and
  (.seatbid[0].bid[0] |
    .crid == "1.1.1" and .price == 2 and
    .ext.prebid.meta.adaptercode == "generic" and
    (.adm | contains("DSP E2E banner") and contains("width:300px;height:250px")))
' "$response" > /dev/null; then
  jq '{id,seatbid,errors:.ext.errors}' "$response" >&2
  exit 1
fi

echo "PBS-Java received the live synthetic bid from local DSP."
