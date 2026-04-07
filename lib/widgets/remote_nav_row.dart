import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';

class RemoteNavRow extends StatelessWidget {
  const RemoteNavRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();
    return Row(
      children: [
        _navButton(icon: Icons.arrow_back_rounded, onTap: () => provider.sendKey('KEY_RETURN')),
        const SizedBox(width: 8),
        _navButton(icon: Icons.home_rounded, onTap: () => provider.sendKey('KEY_HOME')),
        const SizedBox(width: 8),
        _navButton(icon: Icons.input_rounded, onTap: () => provider.sendKey('KEY_SOURCE')),
      ],
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF162033),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white70, size: 26),
        ),
      ),
    );
  }
}
