import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native view and per-view channel are registered', (tester) async {
    final created = <int>[];
    const viewType = 'setupad.plugin.setupad_prebid_flutter';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      width: 320,
      height: 50,
      child: Platform.isAndroid
          ? AndroidView(viewType: viewType, onPlatformViewCreated: created.add)
          : UiKitView(viewType: viewType, onPlatformViewCreated: created.add),
    ))));
    await tester.pumpAndSettle();
    expect(created, hasLength(1));

    if (Platform.isAndroid) {
      final channel = MethodChannel('$viewType/myChannel_${created.single}');
      await channel.invokeMethod<void>('setParams', <String, Object?>{
        'adType': 'banner',
        'configId': '',
        'adUnitId': '',
        'width': 320,
        'height': 50,
        'refreshInterval': 30,
      });
      await channel.invokeMethod<void>('pauseAuction');
      await channel.invokeMethod<void>('resumeAuction');
      await channel.invokeMethod<void>('destroyAuction');
    } else {
      const channel = MethodChannel('$viewType/ios');
      await expectLater(
        channel.invokeMethod<void>('setParams'),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'LOAD_PARAMETERS')),
      );
    }
  });
}
