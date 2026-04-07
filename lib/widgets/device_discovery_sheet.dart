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
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (provider.isScanning)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
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
                style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...provider.discoveredDevices.map(
              (tv) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tv, color: Colors.white54),
                title: Text(tv.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(tv.ip,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
              child: Text('Cihaz bulunamadı. Manuel IP girebilirsiniz.',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ),
          ],
          const Text('Manuel IP Girişi',
              style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '192.168.1.100',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF0D1B2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: () {
                    final ip = _ipController.text.trim();
                    if (ip.isNotEmpty) {
                      provider.connectManual(ip);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Bağlan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }
}
