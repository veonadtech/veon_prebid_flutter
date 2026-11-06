# Flutter adapter CI/CD

## Test coverage

Widget tests for Android and iOS check that `banner`, `interstitial`, and
`rewardVideo` are passed to the native channel with the correct parameters,
platform view size, and callbacks for loading, display, errors, clicks, and
closing. They also check the available controller commands for banners and
interstitial ads. The integration test creates a real native view and checks
channel communication without contacting an ad network. Actual creative loading
and reward delivery depend on an external ad server and are tested in the
native SDKs.

## Branches and reviews

Use one branch per task, named `<type>/AD-123[-description]`, for example
`feature/AD-123` or `bugfix/AD-123-fix-banner`. Allowed types are `feature`,
`bug`, `bugfix`, `hotfix`, `chore`, `ci`, `build`, `test`, `perf`, `refactor`,
and `sec`. The description is optional; its hyphen-separated parts may contain
only Latin letters and digits. The Jira project prefix may be any sequence of
letters, not just `AD`.

Merge task branches into `dev` through PRs. Merge `dev` into `test` through a
PR, then merge `test` into `main` through a PR after validating a release
candidate. Every PR description must contain a Jira link such as
`https://buildx-veon.atlassian.net/browse/AD-123`. For PRs targeting `dev`,
the issue key in the link must match the branch name.

Configure GitHub rulesets for `dev`, `test`, and `main`: block direct pushes,
require at least one approval, require all review conversations to be resolved,
and require the `policy`, `unit`, `android-integration`, and `ios-integration`
checks from the `Flutter adapter CI` workflow. The `policy` check accepts PRs
into `test` only from `dev`, and PRs into `main` only from `test` with
successful `stage`, `stage-ios`, and `candidate-tag` checks on the HEAD of `test`. Configure
the `prod` GitHub Environment with a required reviewer. GitHub rulesets must
require the checks and review before merging.

## Release process

1. Open a PR from a task branch into `dev`: policy → unit/widget → Android/iOS
   integration.
2. Update `version` in `pubspec.yaml` to `X.Y.Z` through a PR into `dev`.
3. Open a PR from `dev` into `test` with the same checks. After merging, the push
   to `test` reruns unit/widget tests and starts `stage` and `stage-ios`:
   PBS-Java and a local DSP run full banner and click E2E on Android and iOS.
   Once both checks succeed, create a candidate tag on the HEAD of `test`: `vX.Y.Z-rc.N` (for
   example, `v0.1.1-rc.1`). CI reruns unit/widget tests and checks the tag
   against the version, the HEAD of `test`, and its successful stage checks.
4. After validating the candidate, open a PR from `test` into `main`. CI checks
   for successful `stage`, `stage-ios`, and `candidate-tag` checks on the HEAD of `test` and
   runs unit/widget and Android/iOS integration tests. Merge after the checks
   and review pass.
5. Create a release tag on the HEAD of `main`, `vX.Y.Z` (for example, `v0.1.1`),
   and push it to origin. CI reruns unit/widget tests and checks the tag against
   `pubspec.yaml` and the HEAD of `main`. After approval in the `prod`
   Environment, CI creates a GitHub Release. Plugin users can reference this
   tag.

Android/iOS integration tests run only for PRs into `dev`, `test`, and `main`.
They do not rerun on pushes to `test` or on tag pushes, so these checks must be
required in the GitHub rulesets for all three branches. They are temporarily
disabled unless the repository Actions variable `RUN_NATIVE_INTEGRATION` is
set to `true`; when unset, their jobs are skipped and satisfy required checks.
Set the variable to `true` to restore both PR integration jobs. The separate
`stage` Android and `stage-ios` iOS E2E jobs still run after a push to `test`.

The stage environment uses an Ubuntu runner for Android and a GitHub-hosted
`macos-15-intel` runner for iOS. Each job starts PBS-Java and the synthetic local DSP in
containers, then checks the rendered banner, click, landing page, and auction
audit. It does not deploy an app or expose a persistent stage URL. The `integration_test`
also checks the Flutter/native boundary on an emulator and a simulator during
PR validation.

## Local Prebid Server fixture

The `e2e/pbs` directory contains a local Prebid Server (PBS) fixture. It uses
stored requests and a stored bid response to return the same 300×250 test
creative on every auction, without contacting a live bidder. No DSP container
participates in this test; the bid and HTML creative are fixture data in PBS.
It also serves the VEON Android SDK configuration at
`/static/e2e-config.json`, with Prebid ahead of GAM. A small audit proxy
records aggregate auction results without
storing device request data. Start and check it with Docker Compose and `jq`:

```sh
docker compose -f e2e/pbs/compose.yaml up -d
bash e2e/pbs/smoke.sh
docker compose -f e2e/pbs/compose.yaml down
```

The audit proxy listens at `http://127.0.0.1:8000` on the host and forwards
requests to PBS. From an Android emulator, the host address is
`http://10.0.2.2:8000`, so the auction endpoint is
`http://10.0.2.2:8000/openrtb2/auction`. The `PBS fixture smoke` workflow can
also be started manually from GitHub Actions. It starts PBS, verifies its
auction response, and runs the Android Flutter integration test with the
emulator. The test initializes the SDK against local PBS, requests the banner
with config ID `test-imp-id`, waits for the display callback, taps the banner,
and waits for the click callback. The ad links to a local landing page served
by the audit proxy. The workflow captures the banner screen with ADB and checks
the creative's background color. The screenshot and test log are uploaded as
the `pbs-android-render` artifact. It then checks that the app fetched the local
SDK config, received the stored PBS bid, and requested the landing page. The
GAM demo tag
`/21775744923/example/fixed-size-banner` is passed to the native loader as a
fallback; the asserted creative is served by the local PBS fixture. The debug
Android app includes the SDK's JS assets so rendering does not depend on a
remote script host.

To run the Android test locally, keep PBS running and use:

```sh
curl --fail --silent --show-error --request POST http://127.0.0.1:8000/__e2e/reset
bash e2e/pbs/run-android-render.sh
bash e2e/pbs/verify-app-auction.sh
```

The runner requires an Android emulator named `emulator-5554`, Flutter, ADB,
and Java 17 or newer. The screenshot is saved at
`e2e/pbs/artifacts/pbs-banner.png`. Android uses Flutter hybrid composition
for the banner's WebView; the previous texture mode delivered display callbacks
but rendered a blank area on the emulator.

The normal Flutter example still uses the VEON production auction URL and
remote configuration. The local PBS test runs as a separate test target, and
the `PBS fixture smoke` workflow is manual rather than a required PR check.

### Real DSP coverage

The optional `dsp` Compose profile starts a local `veonadtech/dsp-bidder`
test runtime alongside PBS-Java. It runs the real DSP router, campaign loader,
targeting, and `/prebid/bid` handler using a synthetic 300×250 campaign.
PBS-Java's generic OpenRTB adapter forwards the auction to this DSP. The test
runtime uses in-memory test services and fixed GeoIP/Udger enrichers; it does
not load production credentials or campaign data. Build it from a checkout of
the private DSP repository (Go and access to its private modules are required):

```sh
bash e2e/pbs/dsp-local/build-local.sh /path/to/dsp-bidder
docker compose -f e2e/pbs/compose.yaml -f e2e/pbs/compose-dsp.yaml --profile dsp up -d
bash e2e/pbs/dsp-local/smoke.sh
bash e2e/pbs/java/smoke.sh
bash e2e/pbs/dsp-local/verify-click.sh
curl --fail --silent --show-error --request POST http://127.0.0.1:8000/__e2e/reset
bash e2e/pbs/run-android-render.sh
bash e2e/pbs/verify-app-auction.sh
```

The build script archives the checkout's HEAD and applies the local test
patches in a temporary directory, leaving the DSP checkout unchanged. The
binary is written to ignored `e2e/pbs/.build/`. The DSP smoke check requires
a live OpenRTB response; the PBS-Java smoke check requires the same creative
through `/openrtb2/auction`. The click check requires a redirect from the DSP
click endpoint to the local landing page. The Android test verifies display,
click callback, the banner's color in `pbs-banner.png`, the landing page's
color in `pbs-landing.png`, the live DSP bid in PBS's response, and a
landing-page request. The separate `PBS fixture smoke` workflow still uses
PBS-Go's stored response.

For the iOS simulator, use the same PBS-Java and local DSP with the iOS Compose
override. It changes the DSP creative, landing page, and impression URLs from
the Android emulator host `10.0.2.2` to `127.0.0.1`. The dedicated Flutter
fixture in `example/lib/pbs_ios_e2e.dart` loads the 300×250 banner and marks it
ready through the audit proxy after `showBanner()`. `RunnerUITests` then taps the
center of the creative and checks for the DSP bid and landing-page request.
The Xcode result bundle contains screenshots before and after the tap. Boot an
iOS simulator, then run:

```sh
bash e2e/pbs/run-ios-render.sh
```

The runner builds the Flutter app before starting the PBS and DSP containers,
so the build does not compete with the local DSP for VM memory. It waits for
the DSP to listen before checking the live bid. The iOS runner needs Flutter,
Xcode, Docker, `jq`, the local DSP binary in
`e2e/pbs/.build/dsp-e2e`, and a booted simulator. Pass a simulator ID to the
runner if more than one is booted. The result bundle path is printed when the
test finishes. The same script runs in the `stage-ios` job after a push to
`test` and through manual workflow dispatch.

The `PBS and local DSP E2E` GitHub Actions workflow runs both platform paths
automatically on every push to `test` and can also be started manually. The
`stage-ios` job installs Docker with Colima on the hosted Intel runner, limits
the Colima VM to 4 GiB RAM and 2 CPUs, installs Flutter and Go through Actions,
and boots an available iPhone simulator. This hosted runner has 14 GiB RAM;
the full iOS job still needs a successful CI run to establish whether the
simulator, Xcode, PBS, and DSP fit together. GitHub has announced that the
`macos-15-intel` image is available until August 2027. Create the `stage`
GitHub Environment without required reviewers so the automatic checks can
start. Configure the repository or `stage` Environment secret
`DSP_E2E_TOKEN` with read access to `veonadtech/dsp-bidder` and its private Go
modules. The workflow checks out a pinned DSP commit and uploads Android
screenshots plus the iOS Xcode result bundle and test log. Both `stage` and
`stage-ios` must pass on the current `test` HEAD before the candidate tag and
the PR into `main` can pass policy. The
`prod` Environment remains the approval gate for the final release.

Run locally with `flutter test`. On a device, run
`cd example && flutter test integration_test/plugin_integration_test.dart -d <device-id>`.
