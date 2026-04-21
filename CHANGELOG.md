# CHANGELOG

# 0.3.0
* Android SDK version updated to 0.3.0
* iOS SDK version updated to 0.1.0
* iOS minimum deployment target raised to 13.0
* Google-Mobile-Ads-SDK upgraded to 13.0.0 (iOS)
### Fixed
* Make NativeDataAsset len optional like iOS
* hb_cache_id_local is not added to targetingKeywords if adObject is null
* Fix bar layout params is null
* Fix Adm native wrapper parsing
* Exception during looking for cache
* Fix Unit tests
### Changed
* Send ifa_type for IFA
* Resume refreshing for Mediation banner
* Readable exceptions and useless logs
* ORTB config for ad unit level (Aligns with iOS implementation)
* Reusable rendering API banner (removes the destruction of Prebid WebView when it is detached
  from the screen. So now the Prebid banner can be used in the RecyclerView and can be reused
  many times to show the advertisement faster.)
* minSdkVersion upgraded to 23
* GAM SDK upgraded to 25.1.0

# 0.2.0
## Changed
* Android SDK version updated to 0.2.0
* iOS version updated to 0.0.5
## Added
* Added useExternalBrowser option (allows opening links in an external browser instead of WebView)

# 0.1.2
## Fixed
* Added necessary files for starting unit tests. Changed test of SDK initialization.
*  Set browser-like User-Agent for redirect request

# 0.1.1
## Changed
* Android SDK version updated to 0.1.1
## Fixed
* Race condition on logging bug fixed

# 0.0.9
## Changed
* Second fragment separator in URL fixed

# 0.0.8
## Fixed
* Fixed DeviceIP
## Changed
* Android SDK has been updated to ver 35
* Kotlin ver has been updated to ver 2.1.0
* Java ver has been updated to ver 17
* Prebid Android SDK ver has been updated to 0.0.7.9

# 0.0.7.5.3
## Changed
* Redirect bug fixed
* Interstitial Rendering method bug fixed

## 0.0.7.5.2
# Changed
* import VeonPrebidMobileGAMEventHandlers to PrebidMobileGAMEventHandlers in the iOS

## 0.0.7.5
# Added
* Added  MultiBanner method (waterfall with SDK priority list)

# Changed
* iOS version updated to 0.0.4

## 0.0.7.4
# Fixed
* Fixed bug with SDK Log
* Fixed bug with Guava
* Fixed bug with Listenable Future

## 0.0.7.3
# Added
* Added low/show/hide methods for Banner

# Changed
* The banner/interstitial does not refresh when displayed again if it was previously loaded successfully
* ExoPlayer migrated to Media3
* targetSdkVersion upgraded to 35

## 0.0.7.2
# Added
* Added  MultiInterstitial method (waterfall with SDK priority list)
* Added low/show/hide methods for Interstitial
* Added the config URL to the SDK initialization method to set the SDK priority and manage logging

# Fixed1
* Fixed bug with changing ver com.google.guava:listenablefuture

## 0.0.7.1
# Fixed
* Fixed bug with the ad is not shown in iOS. 

## 0.0.7
# Changed
* The widget sets the banner size only after the ad is loaded
* Android version updated to 0.0.7
* iOS version updated to 0.0.3

# Added
* added time refresh interval for custom banner's method

## 0.0.6
# Changed
* iOS-sdk version updated to 0.0.2

# Fixed
* iOS: fixed incorrect banner displaying. The iOS rendering method was replaced with separate GAM and Prebid methods

## 0.0.5
# Added
* Added callbacks

# Fixed
* fixed bug with time refresh interval
* fixed ios banner is not displayed for gam banner

## 0.0.4
# Changed
* android-sdk version updated to 0.0.5.1
* iOS: added leading-trailing padding for banners

## 0.0.3
# Changed
* android-sdk version updated to 0.0.4

## 0.0.2
# Changed
* compileSdkVersion is updated to 35
* jvmTarget is updated to Java 11
* Gradle is updated to 8.10.2
* Switched to Veon Android SDK v0.0.3.6
* iOS is enabled
* Google-Mobile-Ads-SDK is updated to 12.3.0
* iOS logs improved
* Updated README

# Added
* minPercSize added for interstitial
* added GAM for Interstitial
* video rewarded is added

## 0.0.1
* iOS is disabled


* Initial release