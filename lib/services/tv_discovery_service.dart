import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/tv_device.dart';

class TVDiscoveryService {
  static const String _ssdpAddress = '239.255.255.250';
  static const int _ssdpPort = 1900;
  static const String _ssdpMessage =
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 3\r\n'
      'ST: urn:samsung.com:device:RemoteControlReceiver:1\r\n'
      '\r\n';

  Future<List<TVDevice>> discover({Duration timeout = const Duration(seconds: 5)}) async {
    final devices = <String, TVDevice>{};
    RawDatagramSocket? socket;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

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
          if (response.contains('Samsung') && !devices.containsKey(ip)) {
            final name = 'Samsung TV ($ip)';
            devices[ip] = TVDevice(ip: ip, name: name, token: '');
          }
        }
      });

      await completer.future;
      timer.cancel();
    } catch (_) {
    } finally {
      socket?.close();
    }

    return devices.values.toList();
  }

  static TVDevice manualDevice(String ip, {String name = 'Samsung TV'}) =>
      TVDevice(ip: ip, name: name, token: '');
}
