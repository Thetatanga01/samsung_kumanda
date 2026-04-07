import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// TV bilgilerini HTTP API ile çeker. HTTP yanıt vermese bile
  /// [fallback] true ise varsayılan isimle cihaz döner.
  static Future<TVDevice?> fetchDeviceInfo(String ip,
      {bool fallback = false}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request =
          await client.getUrl(Uri.parse('http://$ip:8001/api/v2'));
      final response =
          await request.close().timeout(const Duration(seconds: 2));
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
      // HTTP yanıt vermedi — port açık ama HTTP API yok (yeni firmware)
      if (fallback) return TVDevice(ip: ip, name: 'Samsung TV ($ip)', token: '');
      return null;
    }
  }

  /// SSDP ve subnet scan'ı paralel çalıştırır, yalnızca port 8001 açık
  /// (gerçekten erişilebilir TV) cihazları döner.
  Future<List<TVDevice>> discover(
      {Duration timeout = const Duration(seconds: 8)}) async {
    final results = await Future.wait([
      _discoverViaSsdp(timeout: timeout),
      _scanSubnet(timeout: timeout),
    ]);

    // Sonuçları birleştir, IP'ye göre tekilleştir
    final seen = <String>{};
    final combined = <TVDevice>[];
    for (final list in results) {
      for (final device in list) {
        if (seen.add(device.ip)) {
          combined.add(device);
        }
      }
    }
    debugPrint('[Discovery] Bulunan TV: ${combined.map((d) => d.ip).toList()}');
    return combined;
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

      final message = utf8.encode(_ssdpMessage);
      socket.send(message, InternetAddress(_ssdpAddress), _ssdpPort);

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
          // Sadece Samsung TV SSDP yanıtlarını kabul et
          if (!foundIps.contains(ip) &&
              (response.contains('RemoteControlReceiver') ||
                  response.contains('samsung.remote'))) {
            debugPrint('[Discovery] SSDP TV yanıtı: $ip');
            foundIps.add(ip);
          }
        }
      });

      await completer.future;
      timer.cancel();
    } catch (e) {
      debugPrint('[Discovery] SSDP hata: $e');
    } finally {
      socket?.close();
      if (Platform.isAndroid) {
        try {
          await _multicastChannel.invokeMethod('releaseMulticastLock');
        } catch (_) {}
      }
    }

    // Port 8001 TCP erişimi doğrulayarak sahte cihazları filtrele
    final verified = <String>[];
    await Future.wait(
        foundIps.map((ip) => _checkPort(ip, verified, port: 8001)));
    // Port 8001 kapalıysa port 8002 dene
    final remaining = foundIps.difference(verified.toSet());
    await Future.wait(
        remaining.map((ip) => _checkPort(ip, verified, port: 8002)));

    final futures =
        verified.map((ip) => fetchDeviceInfo(ip, fallback: true));
    final devices = await Future.wait(futures);
    return devices.whereType<TVDevice>().toList();
  }

  Future<List<TVDevice>> _scanSubnet(
      {Duration timeout = const Duration(seconds: 12)}) async {
    final localIp = await _getLocalIp();
    if (localIp == null) return [];

    final parts = localIp.split('.');
    if (parts.length != 4) return [];
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
    debugPrint('[Discovery] Subnet taranıyor: $subnet.1-254 (local: $localIp)');

    final foundIps = <String>[];

    // 254 paralel bağlantı Android'de kısıtlanıyor — 20'li batch'ler kullan
    const batchSize = 20;
    for (int start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final batch = <Future<void>>[];
      for (int i = start; i <= end; i++) {
        final ip = '$subnet.$i';
        batch.add(_checkPorts(ip, foundIps));
      }
      await Future.wait(batch);
      if (foundIps.isNotEmpty) {
        debugPrint('[Discovery] Bulunan: $foundIps');
      }
    }

    debugPrint('[Discovery] Subnet scan tamamlandı: $foundIps');

    final deviceFutures =
        foundIps.map((ip) => fetchDeviceInfo(ip, fallback: true));
    final devices = await Future.wait(deviceFutures);
    return devices.whereType<TVDevice>().toList();
  }

  /// Hem port 8001 hem 8002 kontrol eder.
  Future<void> _checkPorts(String ip, List<String> found) async {
    for (final port in [8001, 8002]) {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 800),
        );
        socket.destroy();
        if (!found.contains(ip)) {
          debugPrint('[Discovery] Port $port açık: $ip');
          found.add(ip);
        }
        return;
      } catch (_) {}
    }
  }

  Future<void> _checkPort(String ip, List<String> found,
      {required int port}) async {
    try {
      final socket = await Socket.connect(ip, port,
          timeout: const Duration(milliseconds: 800));
      socket.destroy();
      if (!found.contains(ip)) found.add(ip);
    } catch (_) {}
  }

  Future<String?> _getLocalIp() async {
    // Önce native Android WifiManager'dan gerçek WiFi IP'sini al
    if (Platform.isAndroid) {
      try {
        final ip = await _multicastChannel.invokeMethod<String>('getWifiIp');
        if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
          debugPrint('[Discovery] WiFi IP (native): $ip');
          return ip;
        }
      } catch (_) {}
    }

    // Fallback: Flutter NetworkInterface (wlan* arayüzünü önceliklendir)
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: false);
      // wlan arayüzünü önce dene
      for (final iface in interfaces) {
        if (iface.name.startsWith('wlan')) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) return addr.address;
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
