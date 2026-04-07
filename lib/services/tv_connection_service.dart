import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/tv_device.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class TVConnectionService {
  WebSocket? _socket;
  StreamSubscription? _subscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _token;

  ConnectionStatus get status => _status;
  String? get token => _token;

  final void Function(ConnectionStatus)? onStatusChange;
  final void Function(String)? onTokenReceived;

  TVConnectionService({this.onStatusChange, this.onTokenReceived});

  Future<void> connect(TVDevice tv) async {
    disconnect();
    _updateStatus(ConnectionStatus.connecting);

    // port 8001 dene, başarısız olursa 8002 (SSL, self-signed cert kabul et)
    final attempts = [
      () => WebSocket.connect(
            'ws://${tv.ip}:8001/api/v2/channels/samsung.remote.control',
          ).timeout(const Duration(seconds: 5)),
      () async {
        final ctx = SecurityContext(withTrustedRoots: false);
        final client = HttpClient(context: ctx)
          ..badCertificateCallback = (cert, host, port) => true;
        return WebSocket.connect(
          'wss://${tv.ip}:8002/api/v2/channels/samsung.remote.control',
          customClient: client,
        ).timeout(const Duration(seconds: 5));
      },
    ];

    for (final attempt in attempts) {
      try {
        _socket = await attempt();

        _subscription = _socket!.listen(
          _onMessage,
          onError: (_) => _updateStatus(ConnectionStatus.disconnected),
          onDone: () => _updateStatus(ConnectionStatus.disconnected),
          cancelOnError: true,
        );

        _socket!.add(jsonEncode(buildConnectMessage('Samsung Kumanda')));
        return;
      } catch (_) {
        _socket?.close();
        _socket = null;
      }
    }

    _updateStatus(ConnectionStatus.disconnected);
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = json['event'] as String?;

      if (event == 'ms.channel.connect' ||
          event == 'ms.channel.clientConnect') {
        final newToken = json['data']?['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          _token = newToken;
          onTokenReceived?.call(newToken);
        }
        _updateStatus(ConnectionStatus.connected);
      }
    } catch (_) {}
  }

  void sendKey(String keyCode) {
    if (_status != ConnectionStatus.connected) return;
    _socket?.add(jsonEncode(buildKeyMessage(keyCode)));
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    onStatusChange?.call(status);
  }

  static Map<String, dynamic> buildConnectMessage(String appName) {
    final encodedName = base64Encode(utf8.encode(appName));
    return {
      'method': 'ms.channel.connect',
      'params': {
        'name': encodedName,
        'token': '0',
      },
    };
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
