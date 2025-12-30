import 'dart:io';

void main() async {
  final replacements = {
    'Rs. Rs. ': 'Rs. ',
    'Rs.  Rs. ': 'Rs. ',
    'Rs.   Rs. ': 'Rs. ',
  };

  final libDir = Directory('lib');
  if (!await libDir.exists()) return;

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        String content = await entity.readAsString();
        String original = content;

        // Run multiple times to catch triple or more
        for (int i = 0; i < 3; i++) {
          replacements.forEach((old, replacement) {
            content = content.replaceAll(old, replacement);
          });
        }

        if (content != original) {
          await entity.writeAsString(content);
          print('Fixed: ${entity.path}');
        }
      } catch (e) {
        print('Error processing ${entity.path}: $e');
      }
    }
  }
}
