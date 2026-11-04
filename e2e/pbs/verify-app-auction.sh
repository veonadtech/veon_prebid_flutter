#!/usr/bin/env bash
set -euo pipefail

base_url="${PBS_BASE_URL:-http://127.0.0.1:8000}"
metrics="$(curl --fail --silent --show-error "${base_url}/__e2e/metrics")"

if ! jq --exit-status '.matching > 0 and .bid_found > 0 and .config_fetches > 0 and .landing_hits > 0' \
    <<< "$metrics" > /dev/null; then
  echo "Flutter app did not complete the PBS auction, display, and landing-page click" >&2
  jq . <<< "$metrics" >&2
  exit 1
fi

echo "Flutter app received a PBS banner bid and opened its landing page"
