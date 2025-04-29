# Flutter Prebid plugin
## Prerequisites
* Flutter version at least `2.10.5`
### Android
* `minSdkVersion` at least `24`
* `compileSdkVersion` at least `33`

### iOS 
* in develop

## pubspec.yaml
In your `pubspec.yaml` file’s dependencies include Prebid plugin for Flutter and run 'flutter pub get' command in the terminal.
```yaml
dependencies:
 setupad_prebid_flutter:
   git:
     url: git@github.com:veonadtech/veon_prebid_flutter.git
```

## Adding app ID
After adding plugin to your project, the next step is to add Google Ad Manager app ID to the project.
### Android
Locate your `AndroidManifest.xml` file, then include the `<meta-data>` tag inside the `<application>` tag with your app ID.
```xml
<application>
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-################~##########"/>
   <!--...-->
</application>
```

## SDK initialization
Prebid Mobile initialization is only needed to be done once and it is recommended to initialize it as early as possible in your project.
To initialize it, first include this import in your Dart file:
```dart
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
```

Then, add `initializeSDK()`method.
```dart
const PrebidMobile().initializeSDK(HOST, ACCOUNT_ID, TIMEOUT, PBSDEBUG)
```
* `HOST` is a prebid server host with protocol and path. example: `https://prebid.veonadx.com/openrtb2/auction`
* `ACCOUNT_ID` is a placeholder for your Prebid account ID.
*  `TIMEOUT` is a parameter that sets how much time bidders have to submit their bids. It is important to choose a sufficient timeout - if it is too short, there is a chance to get less bids, and if it is too long, it can slow down ad loading and user might wait too long for the ads to appear.
* `PBSDEBUG` is a boolean type parameter, if it is set to `true`, it adds a debug flag (“test”: 1) into Prebid auction request, which allows to display only test ads and see full Prebid auction response. If none of this is required, you can set it to false.

# Ads integration
Currently this plugin supports two ad formats: banners and interstitial ads. When creating ad object, it is necessary to specify what ad type it is. Ad type can be written in lowercase (“banner”), uppercase (“BANNER”) or capitalization (“Banner”).

The first step in displaying ads is to import ads library:
```dart
import 'package:setupad_prebid_flutter/prebid_ads.dart';
```

## Banner
To display a banner, first you need to create a `PrebidAd` class object and then add it to your widget.
```dart
PrebidAd prebidBanner = const PrebidAd(
  adType: 'banner',
  configId: 'CONFIG_ID',
  adUnitId: 'AD_UNIT_ID',
  width: 300,
  height: 250,
  refreshInterval: 30,
);
//...
@override
  Widget build(BuildContext context) {
    //...
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            prebidAd, //your banner object added to the widget
            //..
         ],
        ),
      ),
    );
  }
```
`AD_UNIT_ID` and `CONFIG_ID` are placeholders for the ad unit ID and config ID parameters. The minimum refresh interval is 30 seconds, and the maximum is 120 seconds.

----
[Prebid Mobile SDK]: https://docs.prebid.org/prebid-mobile/prebid-mobile.html
