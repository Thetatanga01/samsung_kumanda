import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RemoteButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const RemoteButton({
    super.key,
    required this.child,
    this.onTap,
    this.width = double.infinity,
    this.height = 52,
    this.color = const Color(0xFF162033),
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.padding = EdgeInsets.zero,
  });

  @override
  State<RemoteButton> createState() => _RemoteButtonState();
}

class _RemoteButtonState extends State<RemoteButton>
    with SingleTickerProviderStateMixin {
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
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final base = widget.color;
    final light = Color.lerp(base, Colors.white, 0.18)!;
    final dark = Color.lerp(base, Colors.black, 0.30)!;

    return GestureDetector(
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value; // 0 = normal, 1 = pressed

          return Transform.translate(
            // Basılınca 2px aşağı kayar
            offset: Offset(0, t * 2),
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                // Normal: üstten ışık, basılınca tersine döner
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t < 0.5
                      ? [light, base, dark]
                      : [dark, base, light],
                ),
                boxShadow: [
                  // Üst-sol: ışık yansıması (basılınca kaybolur)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06 * (1 - t)),
                    offset: const Offset(-1, -1),
                    blurRadius: 2,
                  ),
                  // Alt-sağ: gölge (basılınca küçülür)
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
        child: widget.child,
      ),
    );
  }
}
