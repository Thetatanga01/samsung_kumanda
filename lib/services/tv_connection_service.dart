import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tv_device.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class TVConnectionService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _token;

  ConnectionStatus get status => _status;
  String? get token => _token;

  final void Function(ConnectionStatus)? onStatusChange;
  final void Function(String)? onTokenReceived;

  TVConnectionService({this.onStatusChange, this.onTokenReceived});

  Future<void> connect(TVDevice tv) async {
    _updateStatus(ConnectionStatus.connecting);
    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(tv.wsUrl),
        connectTimeout: const Duration(seconds: 5),
      );

      _channel!.sink.add(jsonEncode(buildConnectMessage('Samsung Kumanda')));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _updateStatus(ConnectionStatus.disconnected),
        onDone: () => _updateStatus(ConnectionStatus.disconnected),
      );
    } catch (_) {
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = json['event'] as String?;

      if (event == 'ms.channel.connect') {
        final newToken = json['data']?['token'] as String?;
        if (newToken != null) {
          _token = newToken;
          onTokenReceived?.call(newToken);
        }
        _updateStatus(ConnectionStatus.connected);
      }
    } catch (_) {}
  }

  void sendKey(String keyCode) {
    if (_status != ConnectionStatus.connected) return;
    _channel?.sink.add(jsonEncode(buildKeyMessage(keyCode)));
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close(WebSocketStatus.normalClosure);
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
