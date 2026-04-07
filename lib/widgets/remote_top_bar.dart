import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import '../services/tv_connection_service.dart';

class RemoteTopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const RemoteTopBar({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TVProvider>();
    final isConnected = provider.status == ConnectionStatus.connected;

    return Row(
      children: [
        _buildIconButton(
          onTap: () => provider.sendKey('KEY_POWER'),
          child: const Icon(Icons.power_settings_new, color: Color(0xFFE53935), size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: isConnected ? null : onSettingsTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF162033),
                borderRadius: BorderRadius.circular(16),
              ),
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
        ),
        const SizedBox(width: 12),
        _buildIconButton(
          onTap: onSettingsTap,
          child: const Icon(Icons.tune, color: Colors.white70, size: 22),
        ),
      ],
    );
  }

  Widget _buildIconButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF162033),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: child),
      ),
    );
  }
}
