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

  Future<List<TVDevice>> discover(
      {Duration timeout = const Duration(seconds: 5)}) async {
    // 1. SSDP ile dene
    final ssdpDevices = await _discoverViaSsdp(timeout: timeout);
    if (ssdpDevices.isNotEmpty) return ssdpDevices;

    // 2. SSDP boş dönerse subnet taraması yap
    return _scanSubnet(timeout: timeout);
  }

  Future<List<TVDevice>> _discoverViaSsdp(
      {Duration timeout = const Duration(seconds: 5)}) async {
    final devices = <String, TVDevice>{};
    RawDatagramSocket? socket;

    try {
      // Android'de multicast lock al
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
          final response =
              utf8.decode(datagram.data, allowMalformed: true);
          final ip = datagram.address.address;
          if (!devices.containsKey(ip) &&
              (response.contains('Samsung') ||
                  response.contains('LOCATION'))) {
            devices[ip] = TVDevice(ip: ip, name: 'Samsung TV ($ip)', token: '');
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

    return devices.values.toList();
  }

  Future<List<TVDevice>> _scanSubnet(
      {Duration timeout = const Duration(seconds: 8)}) async {
    // Cihazın IP'sini bul, aynı subnet'i tara
    final localIp = await _getLocalIp();
    if (localIp == null) return [];

    final parts = localIp.split('.');
    if (parts.length != 4) return [];
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    final devices = <TVDevice>[];
    final futures = <Future<void>>[];

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(_checkSamsungPort(ip, devices));
    }

    await Future.wait(futures).timeout(timeout, onTimeout: () => []);
    return devices;
  }

  Future<void> _checkSamsungPort(String ip, List<TVDevice> devices) async {
    try {
      final socket = await Socket.connect(ip, 8001,
          timeout: const Duration(milliseconds: 300));
      socket.destroy();
      devices.add(TVDevice(ip: ip, name: 'Samsung TV ($ip)', token: ''));
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
      // 192.168 dışındaki private IP'leri de dene
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
