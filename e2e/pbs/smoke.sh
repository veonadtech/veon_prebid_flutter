#!/usr/bin/env bash
set -euo pipefail

base_url="${PBS_BASE_URL:-http://127.0.0.1:8000}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for attempt in {1..60}; do
  if curl --fail --silent "${base_url}/status" > /dev/null; then
    break
  fi
  if (( attempt == 60 )); then
    echo "PBS did not become ready at ${base_url}/status" >&2
    exit 1
  fi
  sleep 1
done

response="$(curl --fail --silent --show-error \
  --header 'Content-Type: application/json' \
  --data-binary "@${script_dir}/auction-request.json" \
  "${base_url}/openrtb2/auction")"

jq --exit-status '
  .id == "test-auction-id" and
  any(.seatbid[]?; .seat == "pubmatic" and
    any(.bid[]?; .impid == "test-div-1" and
      .price == 1 and .crid == "pbs-test-creative"))
' <<< "$response" > /dev/null || {
  echo "PBS did not return the expected stored banner bid" >&2
  jq . <<< "$response" >&2
  exit 1
}

echo "PBS returned the stored 300x250 banner bid"
