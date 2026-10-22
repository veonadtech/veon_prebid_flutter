# Flutter Prebid plugin

Flutter integration for Prebid, Google Ad Manager (GAM), and Yandex ads.

## Requirements

- Flutter 3.24.0 or newer.
- Android: `minSdkVersion` 23 or newer and `compileSdkVersion` 35 or newer. The example app uses `minSdkVersion` 24.
- iOS 13 or newer.

## Add the plugin

Add the plugin to your app's `pubspec.yaml`, then run `flutter pub get`:

```yaml
dependencies:
  setupad_prebid_flutter:
    git:
      url: git@github.com:veonadtech/veon_prebid_flutter.git
      ref: 0.7.0-yandex
```

### Android repository

The Android SDK dependency is hosted on JitPack. Add it to your app's Gradle repositories (for example, in the root `android/build.gradle`):

```gradle
allprojects {
  repositories {
    maven { url 'https://jitpack.io' }
    google()
    mavenCentral()
  }
}
```

If your app uses `dependencyResolutionManagement` in `android/settings.gradle`, add JitPack there instead.

## Configure the app

### Android

Add your Google Mobile Ads app ID inside `<application>` in `AndroidManifest.xml`:

```xml
<application>
  <meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-################~##########" />
</application>
```

Replace the placeholder with your actual app ID.

### iOS

Open the iOS part of the Flutter app in Xcode.
Open `info.plist`:

Add ```GADApplicationIdentifier```:
Add the key ```GADApplicationIdentifier``` of type String.
In the String value, paste your Google Publisher ID.
For example: ```<string>ca-app-pub-################~##########</string>```.
Replace ```ca-app-pub-################~##########``` with your actual Google Ad Manager app ID.

Add ```SKAdNetworkItems```:
Add the key ```SKAdNetworkItems``` of type Array (from [this page](https://ads.yandex.com/helpcenter/en/dev/ios/skadnetwork#manual-list-implementation)).
Inside the array, add multiple items of type `Dictionary`.
Each dictionary item should contain the key `SKAdNetworkIdentifier` of type `String`.
Copy all the `SKAdNetworkIdentifier` values from the provided example and paste them into your `info.plist`.

Set a nonempty version and positive build number in your app's `pubspec.yaml`, for example `version: 1.0.0+1`. Missing values cause AppMetrica warnings during Yandex SDK initialization. See the [example pubspec.yaml](example/pubspec.yaml).

For Yandex mediation, set `-ObjC` in the app target's **Other Linker Flags**. The plugin initializes Yandex and registers the GAM and Yandex sources during `initializeSDK()`. Pass the remote configuration URL to select their priority.

## SDK initialization

Call `initializeSDK()` once, early in the app lifecycle. Provide your own server URL, remote configuration URL, account ID, and listener:

```dart
import 'package:flutter/widgets.dart';
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
import 'package:setupad_prebid_flutter/prebid_sdk_listener.dart';

class MySdkListener implements PrebidSdkListener {
  @override
  void onSdkInitialized(String status) {}

  @override
  void onSdkInitializeFailed(String errorMessage) {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const PrebidMobile().initializeSDK(
    'https://your-prebid-server/openrtb2/auction',
    'https://your-config-host/config.json',
    'YOUR_ACCOUNT_ID',
    30000, // timeout in milliseconds
    false, // PBS debug
    false, // external browser on Android
    MySdkListener(),
  );
  runApp(const MyApp());
}
```

The remote configuration controls the source priority on iOS. The `pbsDebug` and `externalBrowser` arguments are applied by the Android implementation; iOS currently reads the server URL, config URL, account ID, and timeout. The SDK listener receives initialization callbacks on Android. The iOS implementation reports initialization in native logs and completes the returned `Future`.

## Ads integration

`PrebidAd` accepts an `AdType` enum, not a string. For a banner or interstitial, pass the Prebid `configId`, GAM `gamAdUnitId`, and Yandex `yandexAdUnitId`. The iOS multi-ad loader uses these IDs and the configured source priority. Use a separate `PrebidController` for each ad view.

`AdType.rewardVideo` remains available through the existing Prebid/GAM path; the Yandex multi-ad loader covers banners and interstitials.

Import the ad API, event listener, and type:

```dart
import 'package:flutter/foundation.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/prebid_ads.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';
```

Implement `EventListener` to display an ad after it loads. `onAdLoaded` receives the winning source's ad ID; `onAdFailed` receives an error message:

```dart
class AdEvents implements EventListener {
  AdEvents(this.controller, this.type);

  final PrebidController controller;
  final AdType type;

  @override
  void onAdLoaded(String adId) {
    if (type == AdType.banner) {
      controller.showBanner();
    } else if (type == AdType.interstitial) {
      controller.showInterstitial();
    }
  }

  @override
  void onAdFailed(String errorMessage) => debugPrint('Ad failed: $errorMessage');

  @override
  void onAdDisplayed(String adId) {}

  @override
  void onAdClicked(String adId) {}

  @override
  void onAdClosed(String adId) {}

  @override
  void onAdImpression(String adId) {}
}
```

### Banner

Create the controller and banner in your widget's state, then place `bannerAd` in the widget tree. Creating the platform view starts the initial load; the listener calls `showBanner()` when it succeeds.

```dart
final bannerController = PrebidController();

late final bannerAd = PrebidAd(
  adType: AdType.banner,
  configId: 'YOUR_PREBID_BANNER_CONFIG_ID',
  gamAdUnitId: 'YOUR_GAM_BANNER_AD_UNIT_ID',
  yandexAdUnitId: 'YOUR_YANDEX_BANNER_AD_UNIT_ID',
  width: 320,
  height: 50,
  refreshInterval: 30,
  eventListener: AdEvents(bannerController, AdType.banner),
  prebidController: bannerController,
);

// In build(): include bannerAd in the returned widget tree.
// To request another ad after the view is attached:
// bannerController.loadBanner();
```

On Android, the banner refresh interval must be from 30 to 120 seconds.

### Interstitial

Keep the `PrebidAd` widget mounted so its platform view can load the interstitial. the ad itself is presented by `showInterstitial()` after `onAdLoaded`.

```dart
final interstitialController = PrebidController();

late final interstitialAd = PrebidAd(
  adType: AdType.interstitial,
  configId: 'YOUR_PREBID_INTERSTITIAL_CONFIG_ID',
  gamAdUnitId: 'YOUR_GAM_INTERSTITIAL_AD_UNIT_ID',
  yandexAdUnitId: 'YOUR_YANDEX_INTERSTITIAL_AD_UNIT_ID',
  width: 100,
  height: 100,
  refreshInterval: null,
  eventListener: AdEvents(interstitialController, AdType.interstitial),
  prebidController: interstitialController,
);

// In build(): include interstitialAd in the returned widget tree.
// To load another interstitial after the view is attached:
// interstitialController.loadInterstitial();
```

Use real IDs configured for each source. A Yandex test ad unit ID alone does not make an invalid Prebid config ID or GAM ad unit ID work. Check the native logs (`[Prebid iOS]` on iOS) for the result from each source.
