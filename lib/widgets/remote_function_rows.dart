import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';

class RemoteFunctionRows extends StatelessWidget {
  const RemoteFunctionRows({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();

    return Column(
      children: [
        Row(
          children: [
            _buildFlatButton(
              onTap: () => provider.sendKey('KEY_MUTE'),
              child: const Icon(Icons.volume_off, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 8),
            _buildFlatButton(
              onTap: () {},
              child: _ColorButtonsRow(onTap: (key) => provider.sendKey(key)),
              flex: 2,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildFlatButton(
              onTap: () => provider.sendKey('KEY_INFO'),
              child: const Icon(Icons.info_outline, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 8),
            _buildFlatButton(
              onTap: () => provider.sendKey('KEY_GUIDE'),
              child: const Text('REHBER',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              flex: 2,
            ),
            const SizedBox(width: 8),
            _buildFlatButton(
              onTap: () => provider.sendKey('KEY_MENU'),
              child: const Text('MENÜ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              flex: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlatButton({
    required Widget child,
    required VoidCallback onTap,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF162033),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ColorButtonsRow extends StatelessWidget {
  final void Function(String) onTap;

  const _ColorButtonsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = <(String, Color, String)>[
      ('1', const Color(0xFFE53935), 'KEY_RED'),
      ('2', const Color(0xFF43A047), 'KEY_GREEN'),
      ('3', const Color(0xFF1E88E5), 'KEY_BLUE'),
      ('', const Color(0xFFFDD835), 'KEY_YELLOW'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        final label = item.$1;
        final color = item.$2;
        final key = item.$3;
        return GestureDetector(
          onTap: () => onTap(key),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (label.isNotEmpty)
                Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
