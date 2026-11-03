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
PR, then merge `test` into `main` through a PR after `stage` succeeds. Every PR
description must contain a Jira link such as
`https://buildx-veon.atlassian.net/browse/AD-123`. For PRs targeting `dev`,
the issue key in the link must match the branch name.

Configure GitHub rulesets for `dev`, `test`, and `main`: block direct pushes,
require at least one approval, require all review conversations to be resolved,
and require the `policy`, `unit`, `android-integration`, and `ios-integration`
checks from the `Flutter adapter CI` workflow. Allow PRs into `test` only from
`dev`. Allow PRs into `main` only from `test`, with a successful `stage` check
on the HEAD of `test`. Configure the `prod` GitHub Environment with a required
reviewer. The workflow file alone cannot reliably enforce these restrictions;
GitHub must check them before merging.

## Release process

1. Open a PR from a task branch into `dev`: policy → unit/widget → Android/iOS
   integration.
2. Update `version` in `pubspec.yaml` to `X.Y.Z` through a PR into `dev`.
3. Open a PR from `dev` into `test` with the same checks. After merging, the push
   to `test` reruns only unit/widget tests, then deploys the consumer app to
   `stage` and runs the Playwright smoke test. Once `stage` succeeds, create a
   candidate tag on the HEAD of `test`: `vX.Y.Z-rc.N` (for example,
   `v0.1.1-rc.1`). CI reruns unit/widget tests and checks the tag against the
   version, the HEAD of `test`, and a successful `stage` check on that commit.
4. After validating the candidate, open a PR from `test` into `main`. CI checks
   for a successful `stage` check on the HEAD of `test` and runs unit/widget and
   Android/iOS integration tests. Merge after the checks and review pass.
5. Create a release tag on the HEAD of `main`, `vX.Y.Z` (for example, `v0.1.1`),
   and push it to origin. CI reruns unit/widget tests and checks the tag against
   `pubspec.yaml` and the HEAD of `main`. After approval in the `prod`
   Environment, CI creates a GitHub Release. Plugin users can reference this
   tag.

Android/iOS integration tests run only for PRs into `dev`, `test`, and `main`.
They do not rerun on pushes to `test` or on tag pushes, so these checks must be
required in the GitHub rulesets for all three branches.

For `stage`, set the `STAGE_URL` Environment variable and the
`STAGE_DEPLOY_URL` and `STAGE_DEPLOY_TOKEN` secrets. The webhook must accept a
POST request with `{"sha":"<commit>"}` and return an error if deployment fails.
It must complete only when the application is ready at `STAGE_URL`. Playwright
checks that the web app is available on stage. It does not test native ads;
`integration_test` checks the Flutter/native boundary on an emulator and a
simulator.

Run locally with `flutter test`. On a device, run
`cd example && flutter test integration_test/plugin_integration_test.dart -d <device-id>`.
