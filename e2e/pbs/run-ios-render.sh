#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
simulator_id="${1:-$(xcrun simctl list --json devices booted | jq -r '[.devices[][] | select(.state == "Booted") | .udid][0] // empty')}"

if [[ -z "$simulator_id" ]]; then
  echo "Boot an iOS simulator or pass its device ID as the first argument" >&2
  exit 1
fi

run_dir="$(mktemp -d "${TMPDIR:-/tmp}/pbs-ios-e2e.XXXXXX")"
derived_data="${run_dir}/DerivedData"
result_bundle="${run_dir}/Result.xcresult"
trap 'if [[ -d "$result_bundle" ]]; then echo "iOS E2E result: $result_bundle"; fi' EXIT

flutter_build_args=(build ios --simulator --debug --target lib/pbs_ios_e2e.dart)
if [[ "${PBS_IOS_VERBOSE:-0}" == 1 ]]; then
  flutter_build_args+=(--verbose)
fi
(cd "${repo_root}/example" && flutter "${flutter_build_args[@]}")

(cd "${repo_root}" && \
  docker compose -f e2e/pbs/compose.yaml -f e2e/pbs/compose-dsp.yaml \
    -f e2e/pbs/compose-ios.yaml --profile dsp up -d)
for attempt in {1..60}; do
  if curl --silent --max-time 2 -o /dev/null http://127.0.0.1:9800/prebid/bid; then
    break
  fi
  if (( attempt == 60 )); then
    echo "Local DSP did not become ready within 60 seconds" >&2
    exit 1
  fi
  sleep 1
done
bash "${script_dir}/java/smoke.sh"

(cd "${repo_root}/example/ios" && \
  xcodebuild -workspace Runner.xcworkspace -scheme Runner \
    -destination "platform=iOS Simulator,id=${simulator_id}" \
    -derivedDataPath "$derived_data" \
    -resultBundlePath "$result_bundle" \
    -only-testing:RunnerUITests/PbsBannerUITests/testTapDspBanner \
    -parallel-testing-enabled NO -quiet test)
