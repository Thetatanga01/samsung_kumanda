import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import '../services/tv_connection_service.dart';
import '../widgets/remote_top_bar.dart';
import '../widgets/remote_function_rows.dart';
import '../widgets/remote_dpad.dart';
import '../widgets/remote_nav_row.dart';
import '../widgets/remote_streaming_row.dart';
import '../widgets/remote_bottom_row.dart';
import '../widgets/device_discovery_sheet.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  ConnectionStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = context.watch<TVProvider>().status;
    if (_lastStatus != null && _lastStatus != status) {
      final s = status;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showStatusSnackBar(s);
      });
    }
    _lastStatus = status;
  }

  void _showStatusSnackBar(ConnectionStatus status) {
    String msg;
    Color color;

    switch (status) {
      case ConnectionStatus.connecting:
        msg = 'Bağlanıyor...';
        color = Colors.orange.shade700;
      case ConnectionStatus.connected:
        final name = context.read<TVProvider>().currentDevice?.name ?? 'TV';
        msg = '$name bağlandı ✓';
        color = Colors.green.shade700;
      case ConnectionStatus.disconnected:
        msg = 'Bağlantı kesildi';
        color = Colors.red.shade700;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _showDiscovery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DeviceDiscoverySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
          child: Column(
            children: [
              RemoteTopBar(onSettingsTap: _showDiscovery),
              const SizedBox(height: 14),
              const RemoteFunctionRows(),
              const SizedBox(height: 14),
              const RemoteDPad(),
              const SizedBox(height: 14),
              const RemoteNavRow(),
              const SizedBox(height: 14),
              const RemoteStreamingRow(),
              const SizedBox(height: 10),
              const RemoteBottomRow(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
