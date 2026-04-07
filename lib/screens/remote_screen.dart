import 'package:flutter/material.dart';
import '../widgets/remote_top_bar.dart';
import '../widgets/remote_function_rows.dart';
import '../widgets/remote_dpad.dart';
import '../widgets/remote_nav_row.dart';
import '../widgets/remote_streaming_row.dart';
import '../widgets/remote_bottom_row.dart';
import '../widgets/device_discovery_sheet.dart';

class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key});

  void _showDiscovery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DeviceDiscoverySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            children: [
              RemoteTopBar(onSettingsTap: () => _showDiscovery(context)),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
