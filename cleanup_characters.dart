import 'dart:io';

void main() async {
  final replacements = {
    'â‚¹': 'Rs. ',
    '‚¹': 'Rs. ',
    'Ã—': 'x',
    '₹': 'Rs. ',
    'Rs. ‚¹': 'Rs. ',
  };

  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('lib directory not found');
    return;
  }

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        String content = await entity.readAsString();
        String original = content;

        replacements.forEach((old, replacement) {
          content = content.replaceAll(old, replacement);
        });

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
