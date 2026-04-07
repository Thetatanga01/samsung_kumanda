import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samsung_kumanda/providers/tv_provider.dart';
import 'package:samsung_kumanda/services/tv_connection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') return <String, Object>{};
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );
  });

  group('TVProvider', () {
    late TVProvider provider;

    setUp(() {
      provider = TVProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial status is disconnected', () {
      expect(provider.status, ConnectionStatus.disconnected);
    });

    test('initial device is null', () {
      expect(provider.currentDevice, isNull);
    });

    test('discovered devices starts empty', () {
      expect(provider.discoveredDevices, isEmpty);
    });
  });
}
