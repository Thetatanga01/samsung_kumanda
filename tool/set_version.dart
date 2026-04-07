// Kullanım: dart tool/set_version.dart
// Her deploy öncesi çalıştırın — lib/version.dart dosyasını günceller.
import 'dart:io';

void main() {
  final now = DateTime.now();
  final version =
      '${now.year}.${_pad(now.month)}.${_pad(now.day)} '
      '${_pad(now.hour)}:${_pad(now.minute)}';

  final file = File('lib/version.dart');
  file.writeAsStringSync(
    '// Bu dosya her deploy öncesi `dart tool/set_version.dart` ile otomatik güncellenir.\n'
    "const String kAppVersion = '$version';\n",
  );

  print('Versiyon güncellendi: $version');
}

String _pad(int n) => n.toString().padLeft(2, '0');
