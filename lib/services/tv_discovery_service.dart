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
    // Port 8001 (HTTP) ve 8002 (HTTPS) sırayla dene
    for (final uri in [
      Uri.parse('http://$ip:8001/api/v2/'),
      Uri.parse('https://$ip:8002/api/v2/'),
    ]) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 2)
          ..badCertificateCallback = (cert, host, port) => true;
        final request = await client.getUrl(uri);
        final response =
            await request.close().timeout(const Duration(seconds: 2));
        final body = await response.transform(utf8.decoder).join();
        client.close();

        final json = jsonDecode(body) as Map<String, dynamic>;
        final device = json['device'] as Map<String, dynamic>?;

        // "[TV] Samsung Q60 Series (65)" gibi prefix'i temizle
        final rawName = (device?['name'] as String? ?? '').replaceFirst(RegExp(r'^\[TV\]\s*'), '').trim();
        final name = rawName.isNotEmpty ? rawName : null;
        final model = device?['modelName'] as String?;

        String displayName;
        if (name != null) {
          displayName = name;
        } else if (model != null) {
          displayName = 'Samsung $model';
        } else {
          displayName = 'Samsung TV ($ip)';
        }

        return TVDevice(ip: ip, name: displayName, token: '');
      } catch (_) {
        continue;
      }
    }

    if (fallback) return TVDevice(ip: ip, name: 'Samsung TV ($ip)', token: '');
    return null;
  }

  /// SSDP önce denir, 2 saniye içinde TV bulursa hemen döner.
  /// Bulamazsa subnet scan ile devam eder.
  Future<List<TVDevice>> discover() async {
    // 1) SSDP — ilk TV bulunduğunda veya 2sn geçince tamamlanır
    final ssdpDevices = await _discoverViaSsdp(
      timeout: const Duration(seconds: 2),
      stopOnFirst: true,
    );
    if (ssdpDevices.isNotEmpty) {
      debugPrint('[Discovery] SSDP hızlı sonuç: ${ssdpDevices.map((d) => d.ip).toList()}');
      return ssdpDevices;
    }

    // 2) SSDP boş döndü — subnet scan
    debugPrint('[Discovery] SSDP sonuç yok, subnet scan başlıyor...');
    final subnetDevices = await _scanSubnet();

    final seen = <String>{};
    return [...ssdpDevices, ...subnetDevices]
        .where((d) => seen.add(d.ip))
        .toList();
  }

  Future<List<TVDevice>> _discoverViaSsdp({
    Duration timeout = const Duration(seconds: 2),
    bool stopOnFirst = false,
  }) async {
    final foundIps = <String>{};
    RawDatagramSocket? socket;

    try {
      if (Platform.isAndroid) {
        await _multicastChannel.invokeMethod('acquireMulticastLock');
      }

      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.multicastHops = 10;

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
              (response.contains('RemoteControlReceiver') ||
                  response.contains('samsung.remote'))) {
            debugPrint('[Discovery] SSDP TV yanıtı: $ip');
            foundIps.add(ip);
            // İlk TV bulundu — hemen tamamla
            if (stopOnFirst && !completer.isCompleted) completer.complete();
          }
        }
      });

      // SSDP isteği gönder
      socket.send(utf8.encode(_ssdpMessage),
          InternetAddress(_ssdpAddress), _ssdpPort);

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

    // Port erişimini paralel doğrula
    final verified = <String>[];
    await Future.wait(
        foundIps.map((ip) => _checkPort(ip, verified, port: 8002)));
    final remaining = foundIps.difference(verified.toSet());
    await Future.wait(
        remaining.map((ip) => _checkPort(ip, verified, port: 8001)));

    final devices = await Future.wait(
        verified.map((ip) => fetchDeviceInfo(ip, fallback: true)));
    return devices.whereType<TVDevice>().toList();
  }

  Future<List<TVDevice>> _scanSubnet() async {
    final localIp = await _getLocalIp();
    if (localIp == null) return [];

    final parts = localIp.split('.');
    if (parts.length != 4) return [];
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
    debugPrint('[Discovery] Subnet taranıyor: $subnet.1-254 (local: $localIp)');

    final foundIps = <String>[];

    // 50'li batch — kısa timeout ile Android'de sorunsuz çalışır
    const batchSize = 50;
    for (int start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final batch = <Future<void>>[];
      for (int i = start; i <= end; i++) {
        final ip = '$subnet.$i';
        batch.add(_checkPorts(ip, foundIps));
      }
      await Future.wait(batch);
      // TV bulunduğunda diğer batch'leri bekleme
      if (foundIps.isNotEmpty) {
        debugPrint('[Discovery] Subnet bulunan: $foundIps — tarama durduruluyor');
        break;
      }
    }

    debugPrint('[Discovery] Subnet scan tamamlandı: $foundIps');

    final deviceFutures =
        foundIps.map((ip) => fetchDeviceInfo(ip, fallback: true));
    final devices = await Future.wait(deviceFutures);
    return devices.whereType<TVDevice>().toList();
  }

  /// Hem port 8002 hem 8001 kontrol eder.
  Future<void> _checkPorts(String ip, List<String> found) async {
    for (final port in [8002, 8001]) {
      try {
        final socket = await Socket.connect(ip, port,
            timeout: const Duration(milliseconds: 350));
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
          timeout: const Duration(milliseconds: 350));
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
