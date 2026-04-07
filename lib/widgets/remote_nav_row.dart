import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import 'remote_button.dart';

class RemoteNavRow extends StatelessWidget {
  const RemoteNavRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();
    return Row(
      children: [
        Expanded(
          child: RemoteButton(
            height: 58,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_RETURN'),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 26),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RemoteButton(
            height: 58,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_HOME'),
            child: const Icon(Icons.home_rounded, color: Colors.white70, size: 26),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RemoteButton(
            height: 58,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_SOURCE'),
            child: const Icon(Icons.input_rounded, color: Colors.white70, size: 26),
          ),
        ),
      ],
    );
  }
}
