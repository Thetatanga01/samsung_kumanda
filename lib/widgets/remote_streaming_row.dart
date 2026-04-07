import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';
import 'remote_button.dart';

class RemoteStreamingRow extends StatelessWidget {
  const RemoteStreamingRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TVProvider>();
    return Row(
      children: [
        Expanded(
          child: RemoteButton(
            height: 60,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_PRIMEAPP'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_circle_fill, color: Color(0xFF00A8E1), size: 18),
                SizedBox(width: 5),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('prime',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w400)),
                    Text('video',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RemoteButton(
            height: 60,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_NETFLIX'),
            child: const Text(
              'NETFLIX',
              style: TextStyle(
                color: Color(0xFFE50914),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RemoteButton(
            height: 60,
            borderRadius: BorderRadius.circular(16),
            onTap: () => provider.sendKey('KEY_YOUTUBE'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_circle_filled, color: Color(0xFFFF0000), size: 18),
                SizedBox(width: 4),
                Text('YouTube',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
