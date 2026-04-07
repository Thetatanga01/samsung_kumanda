import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tv_device.dart';
import '../services/tv_connection_service.dart';
import '../services/tv_discovery_service.dart';

class TVProvider extends ChangeNotifier {
  late final TVConnectionService _connectionService;
  final TVDiscoveryService _discoveryService = TVDiscoveryService();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  TVDevice? _currentDevice;
  List<TVDevice> _discoveredDevices = [];
  bool _isScanning = false;

  ConnectionStatus get status => _status;
  TVDevice? get currentDevice => _currentDevice;
  List<TVDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;

  TVProvider() {
    _connectionService = TVConnectionService(
      onStatusChange: (status) {
        _status = status;
        notifyListeners();
      },
      onTokenReceived: (token) async {
        if (_currentDevice != null) {
          _currentDevice = _currentDevice!.copyWith(token: token);
          await _saveDevice(_currentDevice!);
        }
      },
    );
    _loadAndConnect();
  }

  Future<void> _loadAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('last_tv');
    if (json != null) {
      try {
        final device = TVDevice.fromJson(jsonDecode(json) as Map<String, dynamic>);
        await connectTo(device);
      } catch (_) {}
    }
  }

  Future<void> connectTo(TVDevice device) async {
    _currentDevice = device;
    await _connectionService.connect(device);
    notifyListeners();
  }

  Future<void> _saveDevice(TVDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_tv', jsonEncode(device.toJson()));
  }

  void sendKey(String keyCode) => _connectionService.sendKey(keyCode);

  Future<void> scanForDevices() async {
    _isScanning = true;
    _discoveredDevices = [];
    notifyListeners();

    _discoveredDevices = await _discoveryService.discover();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectManual(String ip) async {
    final device = TVDiscoveryService.manualDevice(ip);
    await connectTo(device);
  }

  @override
  void dispose() {
    _connectionService.disconnect();
    super.dispose();
  }
}
