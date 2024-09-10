import 'package:flutter/material.dart';
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
import 'package:setupad_prebid_flutter/prebid_ads.dart';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const PrebidMobile().initializeSDK(
      "https://prebid.veonadx.com/openrtb2/auction"
      "com.arena.banglalinkmela.app",
      3000,
      false
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

  bool _showInterstitial = false;

  PrebidAd prebidBanner = const PrebidAd(
    adType: 'banner',
    configId: 'mybl_android_slot4_commerce_home_320x50',
    adUnitId: '/23081467975,23120258467/mybl_bangladesh/mybl_android_slot4_commerce_home_320x50',
    width: 320,
    height: 50,
    refreshInterval: 30,
  );

  PrebidAd prebidInterstitial = const PrebidAd(
    adType: 'interstitial',
    configId: 'mybl_android_slot4_commerce_home_320x50',
    adUnitId: '/23081467975,23120258467/mybl_bangladesh/mybl_android_slot4_commerce_home_320x50',
    width: 80,
    height: 60,
    refreshInterval: 0,
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
            prebidBanner,
            ElevatedButton(
              child: const Text('show banner'),
              onPressed: () {
                setState(() {
                  prebidBanner.resumeAuction();
                });
              },
            ),
            ElevatedButton(
              child: const Text('show interstitial'),
              onPressed: () {
                _showInterstitial = true;
              },
            ),
            if (_showInterstitial)
              prebidInterstitial,
          ],
        ),
      ),
    );
  }
}

