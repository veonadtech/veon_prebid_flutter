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

compose=(docker compose -f e2e/pbs/compose.yaml -f e2e/pbs/compose-dsp.yaml \
  -f e2e/pbs/compose-ios.yaml --profile dsp)
(cd "${repo_root}" && "${compose[@]}" up -d)
for attempt in {1..60}; do
  if curl --silent --max-time 2 -o /dev/null http://127.0.0.1:9800/prebid/bid; then
    break
  fi
  if (( attempt == 60 )); then
    echo "Local DSP did not become ready within 60 seconds" >&2
    (cd "${repo_root}" && "${compose[@]}" ps) >&2 || true
    (cd "${repo_root}" && "${compose[@]}" port dsp 9800) >&2 || true
    echo "DSP response inside container:" >&2
    (cd "${repo_root}" && "${compose[@]}" exec -T dsp \
      wget -S -O /dev/null http://127.0.0.1:9800/prebid/bid) >&2 || true
    echo "DSP response from host:" >&2
    curl --verbose --max-time 5 -o /dev/null \
      http://127.0.0.1:9800/prebid/bid >&2 || true
    if command -v colima >/dev/null; then
      colima status >&2 || true
    fi
    exit 1
  fi
  sleep 1
done
if ! PBS_READY_TIMEOUT_SECONDS=300 bash "${script_dir}/java/smoke.sh"; then
  echo "PBS-Java diagnostics after readiness failure:" >&2
  echo "Audit /status response:" >&2
  curl --silent --show-error --max-time 5 -i http://127.0.0.1:8000/status >&2 || true
  (cd "${repo_root}" && "${compose[@]}" ps -a) >&2 || true
  pbs_id=$(cd "${repo_root}" && "${compose[@]}" ps -q pbs || true)
  if [[ -n "$pbs_id" ]]; then
    docker inspect --format \
      'PBS state: status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} started={{.State.StartedAt}}' \
      "$pbs_id" >&2 || true
    echo "Requesting two PBS-Java thread dumps, five seconds apart:" >&2
    docker kill --signal=QUIT "$pbs_id" >&2 || true
    sleep 5
    docker kill --signal=QUIT "$pbs_id" >&2 || true
    sleep 2
  fi
  docker stats --no-stream --format \
    'Container: {{.Name}} CPU: {{.CPUPerc}} Memory: {{.MemUsage}}' >&2 || true
  (cd "${repo_root}" && "${compose[@]}" logs --no-color --timestamps pbs) >&2 || true
  exit 1
fi

(cd "${repo_root}/example/ios" && \
  xcodebuild -workspace Runner.xcworkspace -scheme Runner \
    -destination "platform=iOS Simulator,id=${simulator_id}" \
    -derivedDataPath "$derived_data" \
    -resultBundlePath "$result_bundle" \
    -only-testing:RunnerUITests/PbsBannerUITests/testTapDspBanner \
    -parallel-testing-enabled NO -quiet test)
