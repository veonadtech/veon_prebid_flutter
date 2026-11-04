#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
artifact_dir="${script_dir}/artifacts"
log_file="${artifact_dir}/android-render.log"
screenshot="${artifact_dir}/pbs-banner.png"
landing_screenshot="${artifact_dir}/pbs-landing.png"
mkdir -p "$artifact_dir"
: > "$log_file"

(cd "${repo_root}/example" && \
  flutter test integration_test/pbs_banner_integration_test.dart \
    --no-uninstall -d emulator-5554 -r expanded) > "$log_file" 2>&1 &
test_pid=$!
captured=false
landing_captured=false

for attempt in {1..900}; do
  if grep -q 'PBS_CREATIVE_DISPLAYED' "$log_file"; then
    sleep 4
    adb -s emulator-5554 exec-out screencap -p > "$screenshot"
    captured=true
    break
  fi
  if ! kill -0 "$test_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

for attempt in {1..30}; do
  if grep -q 'PBS_CREATIVE_CLICKED' "$log_file"; then
    sleep 4
    adb -s emulator-5554 exec-out screencap -p > "$landing_screenshot"
    landing_captured=true
    break
  fi
  if ! kill -0 "$test_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

if wait "$test_pid"; then
  test_status=0
else
  test_status=$?
fi
cat "$log_file"

if (( test_status != 0 )); then
  exit "$test_status"
fi
if [[ "$captured" != true || ! -s "$screenshot" ]]; then
  echo "No banner screenshot captured" >&2
  exit 1
fi

java "${script_dir}/CheckScreenshot.java" "$screenshot" 142c42 10000
if [[ "$landing_captured" != true || ! -s "$landing_screenshot" ]]; then
  echo "No landing-page screenshot captured" >&2
  exit 1
fi
java "${script_dir}/CheckScreenshot.java" "$landing_screenshot" 0f8e58 10000

echo "Saved Prebid banner screenshot: $screenshot"
echo "Saved landing-page screenshot: $landing_screenshot"
