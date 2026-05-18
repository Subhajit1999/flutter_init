import "dart:io";

import "package:path/path.dart" as p;

class AssetEnsureResult {
  AssetEnsureResult({required this.createdDirs, required this.createdEnv});

  final List<String> createdDirs;
  final bool createdEnv;
}

Future<AssetEnsureResult> ensureAssetsFromPubspec(Directory projectDir) async {
  final pubspec = File(p.join(projectDir.path, "pubspec.yaml"));
  if (!await pubspec.exists()) {
    return AssetEnsureResult(createdDirs: const [], createdEnv: false);
  }

  final content = await pubspec.readAsString();
  final lines = content.split("\n");
  var assets = _extractFlutterAssets(lines);
  if (assets.isEmpty) {
    final allItems = RegExp(r"^\s*-\s+(.+?)\s*$", multiLine: true)
        .allMatches(content)
        .map((m) => m.group(1))
        .whereType<String>()
        .toList();
    assets = allItems
        .where((a) => a.trim() == ".env" || a.trim().startsWith("assets/"))
        .toList();
  }

  final createdDirs = <String>[];
  var createdEnv = false;

  for (final asset in assets) {
    final normalized = asset.trim();
    if (normalized.isEmpty) continue;

    if (normalized == ".env") {
      final env = File(p.join(projectDir.path, ".env"));
      if (!await env.exists()) {
        await env.writeAsString("\n");
        createdEnv = true;
      }
      continue;
    }

    if (normalized.endsWith("/")) {
      final dir = Directory(p.join(projectDir.path, normalized));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        createdDirs.add(p.normalize(normalized));
      }
      continue;
    }

    if (normalized.contains("/")) {
      final dirPath = p.dirname(normalized);
      final dir = Directory(p.join(projectDir.path, dirPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        createdDirs.add(p.normalize(dirPath));
      }
    }
  }

  createdDirs.sort();
  return AssetEnsureResult(createdDirs: createdDirs, createdEnv: createdEnv);
}

List<String> _extractFlutterAssets(List<String> lines) {
  var inFlutter = false;
  var flutterIndent = 0;
  var inAssets = false;
  var assetsIndent = 0;

  final out = <String>[];

  for (final line in lines) {
    if (!inFlutter) {
      final m = RegExp(r"^(\s*)flutter:\s*$").firstMatch(line);
      if (m != null) {
        inFlutter = true;
        flutterIndent = m.group(1)!.length;
      }
      continue;
    }

    final indent = _leadingSpaces(line);
    if (indent <= flutterIndent && line.trim().isNotEmpty) {
      inFlutter = false;
      inAssets = false;
      continue;
    }

    if (!inAssets) {
      final m = RegExp(r"^(\s*)assets:\s*$").firstMatch(line);
      if (m != null) {
        inAssets = true;
        assetsIndent = m.group(1)!.length;
      }
      continue;
    }

    if (indent <= assetsIndent && line.trim().isNotEmpty) {
      inAssets = false;
      continue;
    }

    final item = RegExp(r"^\s*-\s+(.+?)\s*$").firstMatch(line);
    if (item != null) {
      out.add(item.group(1)!);
    }
  }

  return out;
}

int _leadingSpaces(String s) {
  var count = 0;
  while (count < s.length && s.codeUnitAt(count) == 32) {
    count++;
  }
  return count;
}
