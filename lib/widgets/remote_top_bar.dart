import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import '../services/tv_connection_service.dart';
import 'remote_button.dart';

class RemoteTopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const RemoteTopBar({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TVProvider>();
    final isConnected = provider.status == ConnectionStatus.connected;

    return Row(
      children: [
        RemoteButton(
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(16),
          onTap: () => provider.sendKey('KEY_POWER'),
          child: const Icon(Icons.power_settings_new, color: Color(0xFFE53935), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RemoteButton(
            height: 56,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: isConnected ? null : onSettingsTap,
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isConnected
                        ? (provider.currentDevice?.name ?? 'Samsung TV')
                        : 'Cihaz yeniden bağlanıyor...',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
