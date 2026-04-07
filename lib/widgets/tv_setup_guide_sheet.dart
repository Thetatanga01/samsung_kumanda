import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_provider.dart';

class TVSetupGuideSheet extends StatelessWidget {
  const TVSetupGuideSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TVSetupGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF162033),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Başlık
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TV\'ye bağlanılamadı',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('TV\'de IP Uzaktan Kumanda bir kez etkinleştirilmeli',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scrollable içerik
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2019+ model yolu
                  _SectionHeader(label: 'YENİ MODEL (2019+)', color: Colors.blue.shade300),
                  const SizedBox(height: 8),
                  _StepCard(number: 1, text: 'Ayarlar  →  Genel  →  Ağ'),
                  const SizedBox(height: 6),
                  _StepCard(number: 2, text: 'Uzman Ayarlar\'ı seçin'),
                  const SizedBox(height: 6),
                  _StepCard(
                      number: 3,
                      text: '"IP Uzaktan Kumanda"yı Açık yapın',
                      highlight: true),

                  const SizedBox(height: 16),

                  // Daha yeni modeller — alternatif yol
                  _SectionHeader(label: 'ALTERNATİF YOL (bazı modeller)', color: Colors.purple.shade200),
                  const SizedBox(height: 8),
                  _StepCard(number: 1, text: 'Ayarlar  →  Genel  →  Harici Cihaz Yöneticisi'),
                  const SizedBox(height: 6),
                  _StepCard(
                      number: 2,
                      text: '"IP Uzaktan Kumanda"yı Açık yapın',
                      highlight: true),

                  const SizedBox(height: 16),

                  // Önemli not
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.yellow.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.yellow, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ayarı değiştirdikten sonra TV\'yi kapatıp açın. '
                            'Bazı modellerde yeniden başlatmadan ayar etkili olmaz.',
                            style: TextStyle(color: Colors.yellow, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.white38, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu ayar bir kez yapıldıktan sonra TV ekranında '
                            '"İzin ver?" bildirimi çıkar. Tamam\'a bastıktan sonra '
                            'uygulama token kaydeder ve bir daha sormaz.',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<TVProvider>().retryConnection();
                      },
                      child: const Text(
                        'TV\'yi Yeniden Başlattım, Tekrar Dene',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            color: color,
            fontSize: 11,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600));
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String text;
  final bool highlight;

  const _StepCard({
    required this.number,
    required this.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF1565C0).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? const Color(0xFF1565C0).withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: highlight
                  ? const Color(0xFF1565C0)
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: highlight ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: highlight ? Colors.white : Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
