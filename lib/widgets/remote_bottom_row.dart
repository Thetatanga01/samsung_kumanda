import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import 'remote_button.dart';

class RemoteBottomRow extends StatelessWidget {
  const RemoteBottomRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();
    return Row(
      children: [
        Expanded(
          child: RemoteButton(
            height: 58,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_APPS'),
            child: const _AppsGridIcon(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RemoteButton(
            height: 58,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_SCREEN_MIRRORING'),
            child: const Icon(Icons.cast, color: Colors.white70, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RemoteButton(
            height: 58,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_MIC'),
            child: const Icon(Icons.keyboard_alt_outlined, color: Colors.white70, size: 24),
          ),
        ),
      ],
    );
  }
}

class _AppsGridIcon extends StatelessWidget {
  const _AppsGridIcon();

  @override
  Widget build(BuildContext context) {
    const dotColors = [
      Color(0xFFE53935), Color(0xFF43A047), Color(0xFF1E88E5),
      Color(0xFFFDD835), Color(0xFFAB47BC), Color(0xFF00ACC1),
      Color(0xFFFF7043), Color(0xFF66BB6A), Color(0xFF29B6F6),
    ];
    return SizedBox(
      width: 36,
      height: 36,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        children: dotColors
            .map((c) => Container(
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
