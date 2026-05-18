import "dart:io";

class PubspecSanitizeResult {
  PubspecSanitizeResult({required this.changed, required this.removedKeys});

  final bool changed;
  final List<String> removedKeys;
}

Future<PubspecSanitizeResult> sanitizePubspecDuplicates(File pubspec) async {
  if (!await pubspec.exists()) {
    return PubspecSanitizeResult(changed: false, removedKeys: const []);
  }

  final original = await pubspec.readAsLines();
  final output = <String>[];

  final removed = <String>{};
  final seenDeps = <String>{};
  final seenDevDeps = <String>{};

  String section = "";
  bool skippingBlock = false;
  int skippingIndent = 0;

  for (var i = 0; i < original.length; i++) {
    final line = original[i];

    final sectionMatch = RegExp(r"^(dependencies|dev_dependencies):\s*$").firstMatch(line);
    if (sectionMatch != null) {
      section = sectionMatch.group(1)!;
      skippingBlock = false;
      skippingIndent = 0;
      output.add(line);
      continue;
    }

    final indent = _leadingSpaces(line);

    if (skippingBlock) {
      if (indent > skippingIndent) {
        continue;
      }
      skippingBlock = false;
      skippingIndent = 0;
    }

    if (section == "dependencies" || section == "dev_dependencies") {
      final m = RegExp(r"^\s{2}([A-Za-z_][\w_]*):\s*").firstMatch(line);
      if (m != null) {
        final key = m.group(1)!;
        final seen = section == "dependencies" ? seenDeps : seenDevDeps;
        if (seen.contains(key)) {
          removed.add("$section:$key");
          skippingBlock = true;
          skippingIndent = 2;
          continue;
        }
        seen.add(key);
      }
    }

    output.add(line);
  }

  final changed = output.length != original.length;
  if (changed) {
    await pubspec.writeAsString("${output.join("\n")}\n");
  }

  return PubspecSanitizeResult(changed: changed, removedKeys: removed.toList()..sort());
}

int _leadingSpaces(String s) {
  var count = 0;
  while (count < s.length && s.codeUnitAt(count) == 32) {
    count++;
  }
  return count;
}
