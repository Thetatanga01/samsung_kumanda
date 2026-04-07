import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import 'remote_button.dart';

class RemoteSimpleView extends StatelessWidget {
  const RemoteSimpleView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();
    final screenH = MediaQuery.of(context).size.height;
    final dpadSize = (screenH * 0.36).clamp(200.0, 300.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        children: [
          // ── Ana kontrol alanı ─────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol: Ses
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SideBtn(
                        icon: Icons.add,
                        label: 'SES',
                        color: const Color(0xFF1E3A5F),
                        onTap: () => provider.sendKey('KEY_VOLUP'),
                      ),
                      const SizedBox(height: 14),
                      RemoteButton(
                        height: 56,
                        color: const Color(0xFF162033),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => provider.sendKey('KEY_MUTE'),
                        child: const Icon(Icons.volume_off_rounded,
                            color: Colors.white54, size: 26),
                      ),
                      const SizedBox(height: 14),
                      _SideBtn(
                        icon: Icons.remove,
                        label: 'SES',
                        color: const Color(0xFF1E3A5F),
                        onTap: () => provider.sendKey('KEY_VOLDOWN'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Merkez: D-pad
                SizedBox(
                  width: dpadSize,
                  height: dpadSize,
                  child: _BigDpad(provider: provider, size: dpadSize),
                ),

                const SizedBox(width: 14),

                // Sağ: Kanal
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SideBtn(
                        icon: Icons.add,
                        label: 'KANAL',
                        color: const Color(0xFF1E3A5F),
                        onTap: () => provider.sendKey('KEY_CHUP'),
                      ),
                      const SizedBox(height: 14),
                      RemoteButton(
                        height: 56,
                        color: const Color(0xFF162033),
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => provider.sendKey('KEY_CH_LIST'),
                        child: const Icon(Icons.list_rounded,
                            color: Colors.white54, size: 26),
                      ),
                      const SizedBox(height: 14),
                      _SideBtn(
                        icon: Icons.remove,
                        label: 'KANAL',
                        color: const Color(0xFF1E3A5F),
                        onTap: () => provider.sendKey('KEY_CHDOWN'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Alt bar: Geri / Home ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: RemoteButton(
                  height: 62,
                  color: const Color(0xFF162033),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => provider.sendKey('KEY_RETURN'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back_rounded,
                          color: Colors.white70, size: 24),
                      SizedBox(height: 3),
                      Text('Geri',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: RemoteButton(
                  height: 62,
                  color: const Color(0xFF162033),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => provider.sendKey('KEY_HOME'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.home_rounded,
                          color: Colors.white70, size: 24),
                      SizedBox(height: 3),
                      Text('Ana Sayfa',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RemoteButton(
                  height: 62,
                  color: const Color(0xFF162033),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => provider.sendKey('KEY_POWER'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.power_settings_new_rounded,
                          color: Colors.redAccent, size: 24),
                      SizedBox(height: 3),
                      Text('Güç',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Büyük yan buton (VOL / KANAL) ─────────────────────────────────────────────
class _SideBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SideBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RemoteButton(
      height: 72,
      color: color,
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

// ── Büyük D-pad dairesi ───────────────────────────────────────────────────────
class _BigDpad extends StatelessWidget {
  final TVProvider provider;
  final double size;
  const _BigDpad({required this.provider, required this.size});

  @override
  Widget build(BuildContext context) {
    final btnW = size * 0.34;
    final btnH = size * 0.28;
    final okR = size * 0.22;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2D40),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ↑
          Positioned(
            top: size * 0.04,
            child: RemoteButton(
              width: btnW,
              height: btnH,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              onTap: () => provider.sendKey('KEY_UP'),
              child: const Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white70, size: 36),
            ),
          ),
          // ↓
          Positioned(
            bottom: size * 0.04,
            child: RemoteButton(
              width: btnW,
              height: btnH,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              onTap: () => provider.sendKey('KEY_DOWN'),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70, size: 36),
            ),
          ),
          // ←
          Positioned(
            left: size * 0.04,
            child: RemoteButton(
              width: btnH,
              height: btnW,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              onTap: () => provider.sendKey('KEY_LEFT'),
              child: const Icon(Icons.keyboard_arrow_left_rounded,
                  color: Colors.white70, size: 36),
            ),
          ),
          // →
          Positioned(
            right: size * 0.04,
            child: RemoteButton(
              width: btnH,
              height: btnW,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              onTap: () => provider.sendKey('KEY_RIGHT'),
              child: const Icon(Icons.keyboard_arrow_right_rounded,
                  color: Colors.white70, size: 36),
            ),
          ),
          // OK merkez
          RemoteButton(
            width: okR * 2,
            height: okR * 2,
            color: const Color(0xFF2A3F57),
            borderRadius: BorderRadius.circular(okR),
            onTap: () => provider.sendKey('KEY_ENTER'),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
