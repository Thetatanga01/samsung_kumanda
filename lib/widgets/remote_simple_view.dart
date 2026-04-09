import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import 'remote_button.dart';

class RemoteSimpleView extends StatelessWidget {
  const RemoteSimpleView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();
    final size = MediaQuery.of(context).size;
    final dpadSize = (size.width - 64).clamp(240.0, 340.0);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 8),
      child: Column(
        children: [
          // ── D-pad + VOL üzerinde ─────────────────────────────
          Expanded(
            child: Center(
              child: _BigDpad(provider: provider, size: dpadSize),
            ),
          ),

          const SizedBox(height: 16),

          // ── Alt bar ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _BottomBtn(
                  icon: Icons.volume_off_rounded,
                  label: 'Sessiz',
                  onTap: () => provider.sendKey('KEY_MUTE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BottomBtn(
                  icon: Icons.arrow_back_rounded,
                  label: 'Geri',
                  onTap: () => provider.sendKey('KEY_RETURN'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BottomBtn(
                  icon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  onTap: () => provider.sendKey('KEY_HOME'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BottomBtn(
                  icon: Icons.power_settings_new_rounded,
                  label: 'Güç',
                  iconColor: Colors.redAccent,
                  onTap: () => provider.sendKey('KEY_POWER'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Büyük D-pad + VOL+/- dairenin üst kısmında ──────────────────────────────
class _BigDpad extends StatelessWidget {
  final TVProvider provider;
  final double size;
  const _BigDpad({required this.provider, required this.size});

  @override
  Widget build(BuildContext context) {
    final navW = size * 0.30;
    final navH = size * 0.24;
    final okR = size * 0.20;
    final volW = size * 0.26;
    final volH = size * 0.13;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── VOL- sol, VOL+ sağ — dairenin üstünde ──────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _VolBtn(
              width: volW, height: volH,
              icon: Icons.remove,
              label: 'SES -',
              onTap: () => provider.sendKey('KEY_VOLDOWN'),
            ),
            SizedBox(width: size * 0.14),
            _VolBtn(
              width: volW, height: volH,
              icon: Icons.add,
              label: 'SES +',
              onTap: () => provider.sendKey('KEY_VOLUP'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Navigasyon dairesi ──────────────────────────────
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF1A2B3E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ↑
              Positioned(
                top: size * 0.04,
                child: _NavBtn(
                  width: navW, height: navH,
                  icon: Icons.keyboard_arrow_up_rounded,
                  onTap: () => provider.sendKey('KEY_UP'),
                ),
              ),
              // ↓
              Positioned(
                bottom: size * 0.04,
                child: _NavBtn(
                  width: navW, height: navH,
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: () => provider.sendKey('KEY_DOWN'),
                ),
              ),
              // ←
              Positioned(
                left: size * 0.04,
                child: _NavBtn(
                  width: navH, height: navW,
                  icon: Icons.keyboard_arrow_left_rounded,
                  onTap: () => provider.sendKey('KEY_LEFT'),
                ),
              ),
              // →
              Positioned(
                right: size * 0.04,
                child: _NavBtn(
                  width: navH, height: navW,
                  icon: Icons.keyboard_arrow_right_rounded,
                  onTap: () => provider.sendKey('KEY_RIGHT'),
                ),
              ),
              // OK
              RemoteButton(
                width: okR * 2,
                height: okR * 2,
                color: const Color(0xFF243447),
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
        ),
      ],
    );
  }
}

// ── Navigasyon ok butonu ──────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final double width;
  final double height;
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({
    required this.width,
    required this.height,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RemoteButton(
      width: width,
      height: height,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Icon(icon, color: Colors.white70, size: 40),
    );
  }
}

// ── Ses butonu — basılı tutunca tekrar eder ───────────────────────────────────
class _VolBtn extends StatefulWidget {
  final double width;
  final double height;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _VolBtn({
    required this.width,
    required this.height,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_VolBtn> createState() => _VolBtnState();
}

class _VolBtnState extends State<_VolBtn> with SingleTickerProviderStateMixin {
  Timer? _holdTimer;
  bool _pressed = false;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 130),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  int _repeatInterval = 180; // ms — her adımda küçülür

  void _start() {
    if (_pressed) return;
    _pressed = true;
    _repeatInterval = 180;
    _ctrl.forward();
    HapticFeedback.lightImpact();
    widget.onTap();
    // 450ms bekle, sonra hızlanarak tekrarla
    _holdTimer = Timer(const Duration(milliseconds: 450), _repeat);
  }

  void _repeat() {
    if (!_pressed) return;
    HapticFeedback.selectionClick();
    widget.onTap();
    // Her adımda interval'ı %20 kıs, minimum 60ms
    _repeatInterval = (_repeatInterval * 0.80).round().clamp(60, 180);
    _holdTimer = Timer(Duration(milliseconds: _repeatInterval), _repeat);
  }

  void _stop() {
    if (!_pressed) return;
    _pressed = false;
    _ctrl.reverse();
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF1E3A5F);
    final light = Color.lerp(base, Colors.white, 0.18)!;
    final dark = Color.lerp(base, Colors.black, 0.30)!;

    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          return Transform.translate(
            offset: Offset(0, t * 2),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t < 0.5 ? [light, base, dark] : [dark, base, light],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06 * (1 - t)),
                    offset: const Offset(-1, -1),
                    blurRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40 * (1 - t * 0.7)),
                    offset: Offset(0, 3 * (1 - t)),
                    blurRadius: 6 * (1 - t * 0.6),
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: widget.height * 0.55),
            const SizedBox(width: 3),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: widget.height * 0.30,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alt bar butonu ────────────────────────────────────────────────────────────
class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return RemoteButton(
      height: 64,
      color: const Color(0xFF162033),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
