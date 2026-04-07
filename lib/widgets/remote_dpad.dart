import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';

class RemoteDPad extends StatelessWidget {
  const RemoteDPad({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF162033),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _VolumeColumn(onKey: provider.sendKey),
          const SizedBox(width: 16),
          Expanded(child: _DPadCircle(onKey: provider.sendKey)),
          const SizedBox(width: 16),
          _ChannelColumn(onKey: provider.sendKey),
        ],
      ),
    );
  }
}

class _VolumeColumn extends StatelessWidget {
  final void Function(String) onKey;
  const _VolumeColumn({required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideSquareButton(icon: Icons.add, onTap: () => onKey('KEY_VOLUMEUP')),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => onKey('KEY_MUTE'),
          child: const Icon(Icons.volume_up, color: Colors.white70, size: 26),
        ),
        const SizedBox(height: 16),
        _SideSquareButton(icon: Icons.remove, onTap: () => onKey('KEY_VOLUMEDOWN')),
      ],
    );
  }
}

class _ChannelColumn extends StatelessWidget {
  final void Function(String) onKey;
  const _ChannelColumn({required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideSquareButton(icon: Icons.add, onTap: () => onKey('KEY_CHANNELUP')),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => onKey('KEY_CH_LIST'),
          child: const Text('Ç',
              style: TextStyle(
                  color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        _SideSquareButton(icon: Icons.remove, onTap: () => onKey('KEY_CHANNELDOWN')),
      ],
    );
  }
}

class _SideSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SideSquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2D40),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _DPadCircle extends StatelessWidget {
  final void Function(String) onKey;
  const _DPadCircle({required this.onKey});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E2D40),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 10,
              child: GestureDetector(
                onTap: () => onKey('KEY_UP'),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 30),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              child: GestureDetector(
                onTap: () => onKey('KEY_DOWN'),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 30),
                ),
              ),
            ),
            Positioned(
              left: 10,
              child: GestureDetector(
                onTap: () => onKey('KEY_LEFT'),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.keyboard_arrow_left, color: Colors.white70, size: 30),
                ),
              ),
            ),
            Positioned(
              right: 10,
              child: GestureDetector(
                onTap: () => onKey('KEY_RIGHT'),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.keyboard_arrow_right, color: Colors.white70, size: 30),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onKey('KEY_ENTER'),
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF243447),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'TAMAM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
