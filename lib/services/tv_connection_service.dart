import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../models/tv_device.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  waitingForApproval, // TV ekranında onay bekleniyor
  connected,
  setupRequired,
}

class TVConnectionService {
  WebSocket? _socket;
  Socket? _legacySocket;
  StreamSubscription? _subscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _token;

  ConnectionStatus get status => _status;
  String? get token => _token;

  final void Function(ConnectionStatus)? onStatusChange;
  final void Function(String)? onTokenReceived;
  final void Function(String ip)? onDeviceNameResolved;

  TVConnectionService({this.onStatusChange, this.onTokenReceived, this.onDeviceNameResolved});

  Future<void> connect(TVDevice tv) async {
    disconnect();
    _tvIp = tv.ip;
    _updateStatus(ConnectionStatus.connecting);

    if (await _tryWebSocket(tv)) return;
    if (await _tryLegacyTcp(tv)) return;

    // TV kapalı veya ulaşılamıyor — provider retry eder
    debugPrint('[TV] Tüm bağlantı girişimleri başarısız');
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Doğru URL formatıyla WebSocket bağlantısı kurar.
  /// Samsung TV API: name ve token query string'de olmalı.
  Future<bool> _tryWebSocket(TVDevice tv) async {
    final encodedName = base64Encode(utf8.encode('Samsung Kumanda'));
    final token = tv.token.isNotEmpty ? tv.token : null;
    final tokenParam = token != null ? '&token=$token' : '';

    final attempts = <(String, Future<WebSocket> Function())>[
      // Port 8002 (SSL) — yeni Tizen TV'lerde IP Remote olmadan da açık
      (
        'wss://${tv.ip}:8002/api/v2/channels/samsung.remote.control'
            '?name=$encodedName$tokenParam',
        () async {
          final ctx = SecurityContext(withTrustedRoots: false);
          final client = HttpClient(context: ctx)
            ..badCertificateCallback = (cert, host, port) => true;
          return WebSocket.connect(
            'wss://${tv.ip}:8002/api/v2/channels/samsung.remote.control'
            '?name=$encodedName$tokenParam',
            customClient: client,
          ).timeout(const Duration(seconds: 8));
        },
      ),
      // Port 8001 (plain WS) — eski TV'ler veya IP Remote açıkken
      (
        'ws://${tv.ip}:8001/api/v2/channels/samsung.remote.control'
            '?name=$encodedName$tokenParam',
        () => WebSocket.connect(
              'ws://${tv.ip}:8001/api/v2/channels/samsung.remote.control'
              '?name=$encodedName$tokenParam',
            ).timeout(const Duration(seconds: 8)),
      ),
    ];

    for (final (url, attempt) in attempts) {
      debugPrint('[TV] Deneniyor: $url');
      try {
        _socket = await attempt();
        debugPrint('[TV] WebSocket bağlandı: $url');

        _subscription = _socket!.listen(
          _onMessage,
          onError: (e) {
            debugPrint('[TV] Stream hatası: $e');
            _updateStatus(ConnectionStatus.disconnected);
          },
          onDone: () {
            debugPrint('[TV] Bağlantı kapandı');
            _updateStatus(ConnectionStatus.disconnected);
          },
          cancelOnError: true,
        );

        // Bağlantı mesajını URL'deki name ile birlikte gönder
        _socket!.add(jsonEncode(_buildConnectMessage(encodedName, token)));
        debugPrint('[TV] Auth mesajı gönderildi');
        return true;
      } catch (e) {
        debugPrint('[TV] Hata ($url): $e');
        _socket?.close();
        _socket = null;
      }
    }
    return false;
  }

  void _onMessage(dynamic data) {
    debugPrint('[TV] Mesaj: $data');
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = json['event'] as String?;
      debugPrint('[TV] Event: $event');

      switch (event) {
        case 'ms.channel.connect':
        case 'ms.channel.clientConnect':
          final newToken = _extractToken(json['data']);
          if (newToken != null && newToken.isNotEmpty) {
            _token = newToken;
            onTokenReceived?.call(newToken);
            debugPrint('[TV] Token alındı: $newToken');
          }
          _updateStatus(ConnectionStatus.connected);
          _resolveAppIds();
          if (_tvIp != null) onDeviceNameResolved?.call(_tvIp!); // model adını güncelle

        case 'ms.channel.waiting':
          // TV onay bildirimi gösteriyor — kullanıcı OK'lamalı
          debugPrint('[TV] TV onay bekliyor');
          _updateStatus(ConnectionStatus.waitingForApproval);

        case 'ms.channel.timeOut':
          debugPrint('[TV] TV onay zaman aşımı');
          _updateStatus(ConnectionStatus.disconnected);

        case 'ms.channel.unauthorized':
          debugPrint('[TV] TV erişimi reddetti');
          _updateStatus(ConnectionStatus.disconnected);
      }
    } catch (_) {}
  }

  /// TV firmware'ine göre token farklı yerlerde olabilir:
  /// 1) data.token (eski firmware)
  /// 2) data.clients[0].attributes.token (yeni firmware)
  static String? _extractToken(dynamic data) {
    if (data == null) return null;
    Map<String, dynamic>? d;
    if (data is Map<String, dynamic>) {
      d = data;
    } else if (data is String) {
      try { d = jsonDecode(data) as Map<String, dynamic>; } catch (_) {}
    }
    if (d == null) return null;

    // 1) Doğrudan data.token
    final direct = d['token'];
    if (direct is String && direct.isNotEmpty) return direct;

    // 2) data.clients[0].attributes.token
    final clients = d['clients'];
    if (clients is List && clients.isNotEmpty) {
      final attrs = (clients.first as Map<String, dynamic>?)?['attributes'];
      if (attrs is Map<String, dynamic>) {
        final t = attrs['token'];
        if (t is String && t.isNotEmpty) return t;
      }
    }
    return null;
  }

  void sendKey(String keyCode) {
    if (_status != ConnectionStatus.connected) return;
    if (_legacySocket != null) {
      _sendLegacyKey(keyCode);
    } else {
      _socket?.add(jsonEncode(buildKeyMessage(keyCode)));
    }
  }

  String? _tvIp;

  // Her app'in bilinen ID listesi — TV'ye sorgulanarak gerçek ID bulunur
  static const _knownAppIds = {
    'netflix':  ['3201907018807', '11101200001', '3201710014876'],
    'youtube':  ['111299001912',  'org.tizen.youtube-app'],
    'prime':    ['3201512006785', '3201601007250', '3201910019365',
                 'org.tizen.primevideo', 'AmazonInstantVideo'],
  };

  // Çözülmüş app ID'lerini cache'le (bağlantı başına)
  final Map<String, String> _resolvedAppIds = {};

  // TV'ye bağlanıldığında tüm streaming app ID'lerini sorgula
  Future<void> _resolveAppIds() async {
    if (_tvIp == null) return;
    for (final entry in _knownAppIds.entries) {
      for (final id in entry.value) {
        try {
          final client = HttpClient()
            ..connectionTimeout = const Duration(seconds: 2);
          final req = await client
              .getUrl(Uri.parse('http://$_tvIp:8001/api/v2/applications/$id'));
          final res = await req.close().timeout(const Duration(seconds: 2));
          final body = await res.transform(utf8.decoder).join();
          client.close();
          final json = jsonDecode(body) as Map<String, dynamic>;
          if (!json.containsKey('code')) {
            // 404 değil → uygulama var
            _resolvedAppIds[entry.key] = id;
            debugPrint('[TV] App ID çözüldü: ${entry.key} → $id');
            break;
          }
        } catch (_) {}
      }
    }
  }

  Future<void> launchApp(String appKey) async {
    if (_status != ConnectionStatus.connected) return;
    final appId = _resolvedAppIds[appKey] ?? appKey;
    debugPrint('[TV] App launch: $appKey → $appId');

    // 1) REST API — en güvenilir yol
    if (_tvIp != null) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 3);
        final req = await client
            .postUrl(Uri.parse('http://$_tvIp:8001/api/v2/applications/$appId'));
        final res = await req.close().timeout(const Duration(seconds: 3));
        await res.drain<void>();
        client.close();
        debugPrint('[TV] App launch REST ok');
        return;
      } catch (e) {
        debugPrint('[TV] App launch REST hata: $e');
      }
    }

    // 2) WebSocket fallback — data alanı JSON string olmalı
    _socket?.add(jsonEncode({
      'method': 'ms.channel.emit',
      'params': {
        'event': 'ed.apps.launch',
        'to': 'host',
        'data': jsonEncode({'appId': appId, 'action_type': 'DEEP_LINK'}),
      },
    }));
  }

  void _sendLegacyKey(String keyCode) {
    final key = utf8.encode(keyCode);
    final inner = <int>[
      0x00,
0x00,
      0x00,
      key.length & 0xFF,
      0x00,
      ...key,
    ];
    final appId = utf8.encode('iphone.iapp.samsung');
    final msg = <int>[
      0x00,
      appId.length & 0xFF,
      0x00,
      ...appId,
      inner.length & 0xFF,
      0x00,
      ...inner,
    ];
    _legacySocket?.add(msg);
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
    _legacySocket?.destroy();
    _legacySocket = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    onStatusChange?.call(status);
  }

  // ── Legacy TCP (port 7676) ────────────────────────────────────────

  /// Samsung'un eski TCP remote protokolünü dener (2013-2016 arası modeller).
  Future<bool> _tryLegacyTcp(TVDevice tv) async {
    debugPrint('[TV] Legacy TCP 7676 deneniyor: ${tv.ip}');
    try {
      _legacySocket = await Socket.connect(
        tv.ip,
        7676,
        timeout: const Duration(seconds: 4),
      );

      final nameB64 = base64Encode(utf8.encode('Samsung Kumanda'));
      final ipB64 = base64Encode(utf8.encode('0.0.0.0'));
      final macB64 = base64Encode(utf8.encode('00:00:00:00:00:00'));

      final inner = _legacyString(ipB64) +
          _legacyString(macB64) +
          _legacyString(nameB64);
      final appIdBytes = utf8.encode('iphone.iapp.samsung');
      final innerBytes = utf8.encode(inner);

      final msg = <int>[
        0x00,
        appIdBytes.length & 0xFF,
        0x00,
        ...appIdBytes,
        innerBytes.length & 0xFF,
        0x00,
        ...innerBytes,
      ];

      _legacySocket!.add(msg);
      debugPrint('[TV] Legacy TCP bağlandı ve auth gönderildi');

      _subscription = _legacySocket!.listen(
        (data) => debugPrint('[TV] Legacy TCP veri: $data'),
        onError: (e) {
          debugPrint('[TV] Legacy TCP hata: $e');
          _updateStatus(ConnectionStatus.disconnected);
        },
        onDone: () {
          debugPrint('[TV] Legacy TCP kapandı');
          _updateStatus(ConnectionStatus.disconnected);
        },
        cancelOnError: true,
      );

      _updateStatus(ConnectionStatus.connected);
      return true;
    } catch (e) {
      debugPrint('[TV] Legacy TCP başarısız: $e');
      _legacySocket?.destroy();
      _legacySocket = null;
      return false;
    }
  }

  String _legacyString(String s) {
    final bytes = utf8.encode(s);
    return String.fromCharCode(bytes.length) +
        '\x00' +
        String.fromCharCodes(bytes);
  }

  // ── Wake-on-LAN ───────────────────────────────────────────────────

  static Future<String?> _getMacFromArp(String ip) async {
    if (!Platform.isAndroid) return null;
    try {
      final content = await File('/proc/net/arp').readAsString();
      for (final line in content.split('\n')) {
        if (line.trimLeft().startsWith(ip)) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final mac = parts[3];
            if (mac != '00:00:00:00:00:00' && mac.contains(':')) {
              debugPrint('[TV] ARP MAC: $mac');
              return mac;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[TV] ARP okuma hatası: $e');
    }
    return null;
  }

  static Future<void> _sendWolPacket(String ip, String mac) async {
    try {
      final bytes =
          mac.split(':').map((h) => int.parse(h, radix: 16)).toList();
      final magic = Uint8List(102);
      for (int i = 0; i < 6; i++) magic[i] = 0xFF;
      for (int rep = 0; rep < 16; rep++) {
        for (int b = 0; b < 6; b++) {
          magic[6 + rep * 6 + b] = bytes[b];
        }
      }
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(magic, InternetAddress('255.255.255.255'), 9);
      final parts = ip.split('.');
      if (parts.length == 4) {
        socket.send(
            magic,
            InternetAddress('${parts[0]}.${parts[1]}.${parts[2]}.255'),
            9);
      }
      socket.close();
      debugPrint('[TV] WoL gönderildi: $mac');
    } catch (e) {
      debugPrint('[TV] WoL hatası: $e');
    }
  }

  // ── Message builders ──────────────────────────────────────────────

  static Map<String, dynamic> _buildConnectMessage(
      String encodedName, String? token) {
    return {
      'method': 'ms.channel.connect',
      'params': {
        'name': encodedName,
        if (token != null) 'token': token,
      },
    };
  }

  /// Public constructor for connect message (used in diagnostics).
  static Map<String, dynamic> buildConnectMessage(String appName) {
    final encodedName = base64Encode(utf8.encode(appName));
    return _buildConnectMessage(encodedName, null);
  }

  static Map<String, dynamic> buildKeyMessage(String keyCode) => {
        'method': 'ms.remote.control',
        'params': {
          'Cmd': 'Click',
          'DataOfCmd': keyCode,
          'Option': 'false',
          'TypeOfRemote': 'SendRemoteKey',
        },
      };
}
