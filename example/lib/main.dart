import 'package:flutter/material.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
import 'package:setupad_prebid_flutter/prebid_ads.dart';
import 'package:setupad_prebid_flutter/prebid_sdk_listener.dart';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const PrebidMobile().initializeSDK(
      "https://prebid.veonadx.com/openrtb2/auction",
      "https://dcdn.veonadx.com/sdk/uz.beeline.odp/config.json",
      "test",
      30000,
      true,
      _PrebidSdkListener()
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyAppState(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyAppState extends StatefulWidget {
  const MyAppState({required this.title});

  final String title;

  @override
  State<MyAppState> createState() => _MyAppState();
}

class _MyAppState extends State<MyAppState> {
  String _authStatus = 'Unknown';

  final PrebidController _controller = PrebidController();

  List<Widget> adContainer = [];

  late PrebidAd simpleTestBanner;
  late PrebidAd simpleBanner;
  late PrebidAd auctionSimpleBanner;
  late PrebidAd auctionSimpleBanner300x250;
  late PrebidAd interstitial;
  late PrebidAd rewardVideo;

  late _PrebidBannerEventListener _bannerEventListener;
  late _PrebidInterstitialEventListener _interstitialEventListener;

  @override
  void initState() {
    super.initState();

    _bannerEventListener = _PrebidBannerEventListener(_controller);
    _interstitialEventListener = _PrebidInterstitialEventListener(_controller);

    _initializeAds();

    WidgetsFlutterBinding.ensureInitialized()
        .addPostFrameCallback((_) => initPlugin());
  }

  void _initializeAds() {
    simpleTestBanner = PrebidAd(
        adType: AdType.banner,
        configId: '_beeline_uz_android_manual_veon_test_320x50',
        adUnitId: '/23081467975/beeline_uzbekistan_android/beeline_uz_android_manual_veon_test_320x50',
        width: 343,
        height: 100,
        refreshInterval: 30,
        eventListener: _bannerEventListener,
        prebidController: _controller
    );

    simpleBanner = PrebidAd(
        adType: AdType.banner,
        configId: 'prebid-ita-banner-320-50',
        adUnitId: '/6355419/Travel/Europe/France/Paris',
        width: 320,
        height: 50,
        refreshInterval: 30,
        eventListener: _bannerEventListener,
        prebidController: _controller
    );

    auctionSimpleBanner = PrebidAd(
        adType: AdType.banner,
        configId: 'prebid-ita-banner-300-50',
        adUnitId: '/6355419/Travel/Europe/France/Paris',
        width: 300,
        height: 50,
        refreshInterval: 30,
        eventListener: _bannerEventListener,
        prebidController: _controller
    );

    auctionSimpleBanner300x250 = PrebidAd(
        adType: AdType.banner,
        configId: 'prebid-ita-banner-300-250',
        adUnitId: '/6355419/Travel/Europe/France/Paris',
        width: 300,
        height: 250,
        refreshInterval: 30,
        eventListener: _bannerEventListener,
        prebidController: _controller
    );

    interstitial = PrebidAd(
        adType: AdType.interstitial,
        configId: '_beeline_uz_android_wheel_test2_interstitial',
        adUnitId: '/23081467975/beeline_uzbekistan_android/beeline_uz_android_wheel_test2_interstitial',
        width: 50,
        height: 50,
        refreshInterval: null,
        eventListener: _interstitialEventListener,
        prebidController: _controller
    );

    rewardVideo = PrebidAd(
      adType: AdType.rewardVideo,
        configId: 'test_video_content_320x100',
        adUnitId: '/21775744923/example/rewarded',
        width: 100,
        height: 100,
        refreshInterval: null,
        eventListener: _bannerEventListener,
        prebidController: _controller
    );
  }

  Future<void> showCustomTrackingDialog(BuildContext context) async =>
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dear User'),
          content: const Text(
            'We care about your privacy and data security. We keep this app free by showing ads. '
                'Can we continue to use your data to tailor ads for you?\n\nYou can change your choice anytime in the app settings. '
                'Our partners will collect data and use a unique identifier on your device to show you ads.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

  Future<void> initPlugin() async {
    final TrackingStatus status =
    await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await showCustomTrackingDialog(context);
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
      setState(() => _authStatus = '$status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('clear'),
              onPressed: () {
                setState(() {
                  _controller.hideBanner();
                  adContainer.clear();
                });
              },
            ),
            ElevatedButton(
              child: const Text('load Banner'),
              onPressed: () {
                setState(() {
                  _controller.loadBanner();
                });
              },
            ),
            ElevatedButton(
              child: const Text('simple test banner 320x50'),
              onPressed: () {
                setState(() {
                  adContainer.add(simpleTestBanner);
                });
              },
            ),
            ElevatedButton(
              child: const Text('simple banner 320x50'),
              onPressed: () {
                setState(() {
                  adContainer.add(simpleBanner);
                });
              },
            ),
            ElevatedButton(
              child: const Text('auction banner 300x50'),
              onPressed: () {
                setState(() {
                  adContainer.add(auctionSimpleBanner);
                });
              },
            ),
            ElevatedButton(
              child: const Text('auction banner 300x250'),
              onPressed: () {
                setState(() {
                  adContainer.add(auctionSimpleBanner300x250);
                });
              },
            ),
            ElevatedButton(
              child: const Text('interstitial'),
              onPressed: () {
                setState(() {
                  adContainer.add(interstitial);
                });
              },
            ),
            ElevatedButton(
              child: const Text('reward video'),
              onPressed: () {
                setState(() {
                  adContainer.add(rewardVideo);
                });
              },
            ),
            Column(
              children: adContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrebidBannerEventListener implements EventListener {
  final PrebidController _controller;

  _PrebidBannerEventListener(this._controller);

  @override
  onAdLoaded(String configId) {
    print('AAAA Ad loaded: $configId');
    _controller.showBanner();
    // Your logic
  }

  @override
  onAdDisplayed(String configId) {
    print('AAAA Ad displayed: $configId');
    // Your logic
  }

  @override
  onAdFailed(String errorMessage) {
    print('AAAA Ad failed: $errorMessage');
    // Your logic
  }

  @override
  onAdClicked(String configId) {
    print('AAAA Ad clicked: $configId');
    // Your logic
  }

  @override
  onAdUrlClicked(String configId) {
    print('AAAA Ad URL clicked: $configId');
    // Your logic
  }

  @override
  onAdClosed(String configId) {
    print('AAAA Ad closed: $configId');
    // Your logic
  }
}

class _PrebidInterstitialEventListener implements EventListener {
  final PrebidController _controller;

  _PrebidInterstitialEventListener(this._controller);

  @override
  onAdLoaded(String configId) {
    print('AAAA Ad loaded: $configId');
    _controller.showInterstitial();
    //Future.delayed(const Duration(seconds: 3), _controller.hideInterstitial);
    // Your logic
  }

  @override
  onAdDisplayed(String configId) {
    print('AAAA Ad displayed: $configId');
    // Your logic
  }

  @override
  onAdFailed(String errorMessage) {
    print('AAAA Ad failed: $errorMessage');
    // Your logic
  }

  @override
  onAdClicked(String configId) {
    print('AAAA Ad clicked: $configId');
    // Your logic
  }

  @override
  onAdUrlClicked(String configId) {
    print('AAAA Ad URL clicked: $configId');
    // Your logic
  }

  @override
  onAdClosed(String configId) {
    print('AAAA Ad closed: $configId');
    _controller.hideInterstitial();
    // Your logic
  }
}

class _PrebidSdkListener implements PrebidSdkListener {

  @override
  onSdkInitialized(String status) {
    // TODO: implement onSdkInitialized
    debugPrint("PrebidSdkListener1: initialized $status");
    throw UnimplementedError();
  }

  @override
  onSdkInitializeFailed(String errorMessage) {
    // TODO: implement onSdkInitializeFailed
    debugPrint("PrebidSdkListener1: prebidSdkInitializeFailed $errorMessage");
    throw UnimplementedError();
  }

}