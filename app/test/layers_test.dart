import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The command-line tools (tool/) run on the plain Dart VM, so everything they import must stay free of Flutter.
void main() {
  test('protocol, cloud and robot client do not depend on Flutter', () {
    final seen = <String>{};
    final queue = [for (final f in Directory('tool').listSync().whereType<File>()) f.path];
    final offenders = <String>[];
    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      if (!seen.add(path)) continue;
      final src = File(path).readAsStringSync();
      if (src.contains("package:flutter/")) offenders.add(path);
      for (final m in RegExp(r"^import '([^']+)'", multiLine: true).allMatches(src)) {
        final uri = m.group(1)!;
        if (uri.startsWith('package:aspira/')) {
          queue.add('lib/${uri.substring('package:aspira/'.length)}');
        } else if (!uri.contains(':')) {
          queue.add(File(path).parent.uri.resolve(uri).toFilePath());
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
