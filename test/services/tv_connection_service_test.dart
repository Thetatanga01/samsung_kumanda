import 'package:flutter_test/flutter_test.dart';
import 'package:samsung_kumanda/services/tv_connection_service.dart';

void main() {
  group('TVConnectionService', () {
    test('buildConnectMessage returns valid JSON structure', () {
      final msg = TVConnectionService.buildConnectMessage('TestApp');
      expect(msg['method'], 'ms.channel.connect');
      expect(msg['params'], isA<Map>());
      expect(msg['params']['name'], isNotNull);
    });

    test('buildKeyMessage returns valid key command', () {
      final msg = TVConnectionService.buildKeyMessage('KEY_POWER');
      expect(msg['method'], 'ms.remote.control');
      expect(msg['params']['DataOfCmd'], 'KEY_POWER');
      expect(msg['params']['Cmd'], 'Click');
    });
  });
}
