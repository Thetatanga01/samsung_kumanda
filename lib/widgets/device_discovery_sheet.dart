import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';

class DeviceDiscoverySheet extends StatefulWidget {
  const DeviceDiscoverySheet({super.key});

  @override
  State<DeviceDiscoverySheet> createState() => _DeviceDiscoverySheetState();
}

class _DeviceDiscoverySheetState extends State<DeviceDiscoverySheet> {
  final _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TVProvider>().scanForDevices();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostic(String ip) async {
    final lines = <_DiagLine>[];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DiagDialog(ip: ip, lines: lines),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TVProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF162033),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Cihaz Seç',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (provider.isScanning)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white54))
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => provider.scanForDevices(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.discoveredDevices.isNotEmpty) ...[
            const Text('Bulunan Cihazlar',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...provider.discoveredDevices.map(
              (tv) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tv, color: Colors.white54),
                title: Text(tv.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(tv.ip,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                onTap: () {
                  provider.connectTo(tv);
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 4),
          ] else if (!provider.isScanning) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Cihaz bulunamadı. IP girebilirsiniz.',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ),
          ],
          const Text('Manuel IP Girişi',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    hintText: '192.168.1.100',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF0D1B2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () {
                    final ip = _ipController.text.trim();
                    if (ip.isNotEmpty) {
                      provider.connectManual(ip);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Bağlan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2D40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    final ip = _ipController.text.trim();
                    if (ip.isNotEmpty) _runDiagnostic(ip);
                  },
                  child: const Icon(Icons.bug_report_outlined,
                      color: Colors.white54, size: 20),
                ),
              ),
            ],
          ),
          SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }
}

// ── Diagnostic Dialog ──────────────────────────────────────────────

class _DiagLine {
  final String text;
  final bool? ok; // null = running, true = ok, false = fail
  _DiagLine(this.text, {this.ok});
}

class _DiagDialog extends StatefulWidget {
  final String ip;
  final List<_DiagLine> lines;
  const _DiagDialog({required this.ip, required this.lines});

  @override
  State<_DiagDialog> createState() => _DiagDialogState();
}

class _DiagDialogState extends State<_DiagDialog> {
  final _log = <_DiagLine>[];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _add(String text, {bool? ok}) {
    if (!mounted) return;
    setState(() => _log.add(_DiagLine(text, ok: ok)));
  }

  Future<void> _run() async {
    final ip = widget.ip;

    // 1. TCP 8001
    _add('TCP bağlantısı: $ip:8001', ok: null);
    try {
      final s = await Socket.connect(ip, 8001,
          timeout: const Duration(seconds: 3));
      s.destroy();
      _add('✓ Port 8001 açık', ok: true);
    } catch (e) {
      _add('✗ Port 8001 kapalı: $e', ok: false);
    }

    // 2. HTTP /api/v2
    _add('HTTP API: http://$ip:8001/api/v2');
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final req = await client.getUrl(
          Uri.parse('http://$ip:8001/api/v2'));
      final res = await req.close().timeout(const Duration(seconds: 3));
      final body = await res.transform(utf8.decoder).join();
      client.close();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final dev = json['device'] as Map<String, dynamic>?;
      final name = dev?['name'] ?? dev?['modelName'] ?? '?';
      _add('✓ TV bulundu: $name', ok: true);
    } catch (e) {
      _add('✗ HTTP hatası: $e', ok: false);
    }

    // 3. TCP 8002
    _add('TCP bağlantısı: $ip:8002');
    try {
      final s = await Socket.connect(ip, 8002,
          timeout: const Duration(seconds: 3));
      s.destroy();
      _add('✓ Port 8002 açık', ok: true);
    } catch (e) {
      _add('✗ Port 8002 kapalı: $e', ok: false);
    }

    // 4. WebSocket
    _add('WebSocket: ws://$ip:8001/api/v2/...');
    try {
      final socket = await WebSocket.connect(
        'ws://$ip:8001/api/v2/channels/samsung.remote.control',
      ).timeout(const Duration(seconds: 5));
      _add('✓ WebSocket bağlandı', ok: true);
      await socket.close();
    } catch (e) {
      _add('✗ WebSocket hatası: $e', ok: false);
    }

    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF162033),
      title: Text('Bağlantı Testi — ${widget.ip}',
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: _log.map((l) {
            Color c = Colors.white70;
            if (l.ok == true) c = Colors.greenAccent;
            if (l.ok == false) c = Colors.redAccent;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(l.text,
                  style: TextStyle(color: c, fontSize: 12)),
            );
          }).toList(),
        ),
      ),
      actions: _done
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat',
                    style: TextStyle(color: Colors.white70)),
              )
            ]
          : [
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            ],
    );
  }
}
