# CHANGELOG

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