import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/tv_device.dart';

class TVDiscoveryService {
  static const _multicastChannel =
      MethodChannel('com.mustafaguven.samsung_kumanda/multicast');

  static const String _ssdpAddress = '239.255.255.250';
  static const int _ssdpPort = 1900;
  static const String _ssdpMessage =
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 3\r\n'
      'ST: urn:samsung.com:device:RemoteControlReceiver:1\r\n'
      '\r\n';

  /// IP adresinden Samsung TV bilgilerini HTTP API ile çek
  static Future<TVDevice?> fetchDeviceInfo(String ip) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse('http://$ip:8001/api/v2'));
      final response = await request.close().timeout(const Duration(seconds: 2));
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final device = json['device'] as Map<String, dynamic>?;

      final name = (device?['name'] as String?)?.isNotEmpty == true
          ? device!['name'] as String
          : null;
      final model = device?['modelName'] as String?;

      String displayName;
      if (name != null && model != null) {
        displayName = '$name ($model)';
      } else if (model != null) {
        displayName = 'Samsung $model';
      } else if (name != null) {
        displayName = name;
      } else {
        displayName = 'Samsung TV ($ip)';
      }

      return TVDevice(ip: ip, name: displayName, token: '');
    } catch (_) {
      return TVDevice(ip: ip, name: 'Samsung TV ($ip)', token: '');
    }
  }

  Future<List<TVDevice>> discover(
      {Duration timeout = const Duration(seconds: 5)}) async {
    final ssdpDevices = await _discoverViaSsdp(timeout: timeout);
    if (ssdpDevices.isNotEmpty) return ssdpDevices;
    return _scanSubnet(timeout: timeout);
  }

  Future<List<TVDevice>> _discoverViaSsdp(
      {Duration timeout = const Duration(seconds: 5)}) async {
    final foundIps = <String>{};
    RawDatagramSocket? socket;

    try {
      if (Platform.isAndroid) {
        await _multicastChannel.invokeMethod('acquireMulticastLock');
      }

      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.multicastHops = 10;

      final multicastAddress = InternetAddress(_ssdpAddress);
      final message = utf8.encode(_ssdpMessage);
      socket.send(message, multicastAddress, _ssdpPort);

      final completer = Completer<void>();
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram == null) return;
          final response = utf8.decode(datagram.data, allowMalformed: true);
          final ip = datagram.address.address;
          if (!foundIps.contains(ip) &&
              (response.contains('Samsung') || response.contains('LOCATION'))) {
            foundIps.add(ip);
          }
        }
      });

      await completer.future;
      timer.cancel();
    } catch (_) {
    } finally {
      socket?.close();
      if (Platform.isAndroid) {
        try {
          await _multicastChannel.invokeMethod('releaseMulticastLock');
        } catch (_) {}
      }
    }

    // Bulunan IP'lerin model adlarını paralel çek
    final futures = foundIps.map((ip) => fetchDeviceInfo(ip));
    final results = await Future.wait(futures);
    return results.whereType<TVDevice>().toList();
  }

  Future<List<TVDevice>> _scanSubnet(
      {Duration timeout = const Duration(seconds: 8)}) async {
    final localIp = await _getLocalIp();
    if (localIp == null) return [];

    final parts = localIp.split('.');
    if (parts.length != 4) return [];
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    final foundIps = <String>[];
    final futures = <Future<void>>[];

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(_checkPort(ip, foundIps));
    }

    await Future.wait(futures).timeout(timeout, onTimeout: () => []);

    // Bulunan IP'lerin model adlarını paralel çek
    final deviceFutures = foundIps.map((ip) => fetchDeviceInfo(ip));
    final devices = await Future.wait(deviceFutures);
    return devices.whereType<TVDevice>().toList();
  }

  Future<void> _checkPort(String ip, List<String> found) async {
    try {
      final socket = await Socket.connect(ip, 8001,
          timeout: const Duration(milliseconds: 300));
      socket.destroy();
      found.add(ip);
    } catch (_) {}
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: false);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168')) {
            return addr.address;
          }
        }
      }
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  static TVDevice manualDevice(String ip, {String name = 'Samsung TV'}) =>
      TVDevice(ip: ip, name: name, token: '');
}
