import 'package:flutter/material.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
import 'package:setupad_prebid_flutter/prebid_ads.dart';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const PrebidMobile().initializeSDK(
      "https://prebid-01.veonadx.com/openrtb2/auction",
      "test",
      30000,
      true
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

  @override
  void initState() {
  super.initState();

  WidgetsFlutterBinding.ensureInitialized()
      .addPostFrameCallback((_) => initPlugin());
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

  List<Widget> adContainer = [];

  PrebidAd simpleTestBanner = PrebidAd(
    adType: AdType.banner,
    configId: 'test_320x50',
    adUnitId: '/6355419/Travel/Europe/France/Paris',
    width: 320,
    height: 50,
    refreshInterval: 30,
    eventListener: _PrebidEventListener(),
  );

  PrebidAd simpleBanner = PrebidAd(
    adType: AdType.banner,
    configId: 'prebid-ita-banner-320-50',
    adUnitId: '/6355419/Travel/Europe/France/Paris',
    width: 320,
    height: 50,
    refreshInterval: 30,
    eventListener: _PrebidEventListener(),
  );

  PrebidAd auctionSimpleBanner = PrebidAd(
    adType: AdType.banner,
    configId: 'prebid-ita-banner-300-50',
    adUnitId: '/6355419/Travel/Europe/France/Paris',
    width: 300,
    height: 50,
    refreshInterval: 30,
    eventListener: _PrebidEventListener(),
  );

  PrebidAd auctionSimpleBanner300x250 = PrebidAd(
    adType: AdType.banner,
    configId: 'prebid-ita-banner-300-250',
    adUnitId: '/6355419/Travel/Europe/France/Paris',
    width: 300,
    height: 250,
    refreshInterval: 30,
    eventListener: _PrebidEventListener(),
  );

  PrebidAd interstitial = PrebidAd(
    adType: AdType.interstitial,
    configId: 'test_interstitial',
    adUnitId: '/21775744923/example/interstitial',
    width: 50,
    height: 50,
    refreshInterval: null,
    eventListener: _PrebidEventListener(),
  );

  PrebidAd rewardVideo = PrebidAd(
    adType: AdType.rewardVideo,
    configId: 'test_video_content_320x100',
    adUnitId: '/21775744923/example/rewarded',
    width: 100,
    height: 100,
    refreshInterval: null,
    eventListener: _PrebidEventListener(),
  );

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
                  adContainer.clear();
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

class _PrebidEventListener implements EventListener {
  @override
  onAdLoaded(String configId) {
    print('AAAA Ad loaded: $configId');
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