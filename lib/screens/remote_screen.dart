import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import '../services/tv_connection_service.dart';
import '../widgets/remote_top_bar.dart';
import '../widgets/remote_function_rows.dart';
import '../widgets/remote_dpad.dart';
import '../widgets/remote_nav_row.dart';
import '../widgets/remote_streaming_row.dart';
import '../widgets/remote_bottom_row.dart';
import '../widgets/remote_simple_view.dart';
import '../widgets/device_discovery_sheet.dart';
import '../widgets/tv_setup_guide_sheet.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen>
    with WidgetsBindingObserver {
  static const _volumeChannel =
      EventChannel('com.mustafaguven.samsung_kumanda/volume_keys');
  StreamSubscription? _volumeSub;
  ConnectionStatus? _lastStatus;
  DateTime? _pausedAt;

  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _volumeSub = _volumeChannel.receiveBroadcastStream().listen((key) {
      if (mounted) context.read<TVProvider>().sendKey(key as String);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _volumeSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && mounted) {
      final provider = context.read<TVProvider>();
      if (provider.status == ConnectionStatus.disconnected &&
          provider.currentDevice != null) {
        // Kısa arka plan geçişlerinde (bildirim açma vs.) bağlantıya dokunma
        final inBackground = _pausedAt != null &&
            DateTime.now().difference(_pausedAt!) > const Duration(seconds: 5);
        if (inBackground) provider.retryConnection();
      }
      _pausedAt = null;
    }
  }

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
      case ConnectionStatus.waitingForApproval:
        msg = 'TV ekranında "İzin Ver"e basın';
        color = Colors.blue.shade700;
      case ConnectionStatus.disconnected:
        msg = 'Bağlantı kesildi';
        color = Colors.red.shade700;
      case ConnectionStatus.setupRequired:
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) TVSetupGuideSheet.show(context);
        });
        return;
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
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: RemoteTopBar(onSettingsTap: _showDiscovery),
            ),

            const SizedBox(height: 10),

            // ── Mod göstergesi ───────────────────────────────────
            _ModeIndicator(
              currentPage: _currentPage,
              onTap: (i) {
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),

            const SizedBox(height: 10),

            // ── Sayfalar ─────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // Sayfa 0: Tam kumanda
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
                    child: const Column(
                      children: [
                        RemoteFunctionRows(),
                        SizedBox(height: 14),
                        RemoteDPad(),
                        SizedBox(height: 14),
                        RemoteNavRow(),
                        SizedBox(height: 14),
                        RemoteStreamingRow(),
                        SizedBox(height: 10),
                        RemoteBottomRow(),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Sayfa 1: Basit mod
                  Padding(
                    padding: EdgeInsets.only(bottom: bottomPad),
                    child: const RemoteSimpleView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mod seçici pill ──────────────────────────────────────────────────────────
class _ModeIndicator extends StatelessWidget {
  final int currentPage;
  final void Function(int) onTap;
  const _ModeIndicator({required this.currentPage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF162033),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Tab(label: 'Tam Kumanda', active: currentPage == 0, onTap: () => onTap(0)),
          _Tab(label: 'Kolay Mod', active: currentPage == 1, onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1565C0) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
