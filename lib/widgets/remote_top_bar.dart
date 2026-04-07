import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import '../services/tv_connection_service.dart';
import 'remote_button.dart';
import 'tv_setup_guide_sheet.dart';

class RemoteTopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const RemoteTopBar({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TVProvider>();
    final status = provider.status;
    final isConnected = status == ConnectionStatus.connected;
    final needsSetup = status == ConnectionStatus.setupRequired;
    final waitingApproval = status == ConnectionStatus.waitingForApproval;

    return Row(
      children: [
        RemoteButton(
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(16),
          onTap: () => provider.sendKey('KEY_POWER'),
          child: const Icon(Icons.power_settings_new,
              color: Color(0xFFE53935), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RemoteButton(
            height: 56,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: needsSetup
                ? () => TVSetupGuideSheet.show(context)
                : (isConnected ? null : onSettingsTap),
            child: Row(
              children: [
                Icon(
                  needsSetup
                      ? Icons.warning_amber_rounded
                      : (waitingApproval
                          ? Icons.notifications_active
                          : (isConnected
                              ? Icons.wifi_tethering
                              : Icons.wifi_tethering_off)),
                  color: needsSetup
                      ? Colors.orange
                      : (waitingApproval ? Colors.blue.shade300 : Colors.white54),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isConnected
                        ? (provider.currentDevice?.name ?? 'Samsung TV')
                        : (needsSetup
                            ? 'TV ayarı gerekli — dokunun'
                            : (waitingApproval
                                ? 'TV\'de "İzin Ver"e basın'
                                : 'Bağlanıyor...')),
                    style: TextStyle(
                      color: needsSetup
                          ? Colors.orange
                          : (waitingApproval
                              ? Colors.blue.shade300
                              : Colors.white70),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        RemoteButton(
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(16),
          onTap: onSettingsTap,
          child: const Icon(Icons.tune, color: Colors.white70, size: 22),
        ),
      ],
    );
  }
}
