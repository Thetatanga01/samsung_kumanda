import 'package:flutter_test/flutter_test.dart';
import 'package:samsung_kumanda/models/tv_device.dart';

void main() {
  group('TVDevice', () {
    test('fromJson parses correctly', () {
      final json = {
        'ip': '192.168.1.100',
        'name': 'Living Room TV',
        'token': 'abc123',
      };
      final tv = TVDevice.fromJson(json);
      expect(tv.ip, '192.168.1.100');
      expect(tv.name, 'Living Room TV');
      expect(tv.token, 'abc123');
    });

    test('toJson serializes correctly', () {
      final tv = TVDevice(ip: '192.168.1.100', name: 'TV', token: 'tok');
      final json = tv.toJson();
      expect(json['ip'], '192.168.1.100');
      expect(json['token'], 'tok');
    });

    test('wsUrl returns correct websocket url', () {
      final tv = TVDevice(ip: '192.168.1.100', name: 'TV', token: '');
      expect(tv.wsUrl, 'ws://192.168.1.100:8001/api/v2/channels/samsung.remote.control');
    });
  });
}
