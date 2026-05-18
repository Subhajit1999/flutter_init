import "dart:io";

import "package:archive/archive.dart";
import "package:path/path.dart" as p;

class ApplyPlan {
  ApplyPlan({
    required this.conflicts,
    required this.filesToWrite,
  });

  final List<String> conflicts;
  final List<String> filesToWrite;
}

Future<Directory> extractZipToStaging({
  required File zipFile,
  required Directory stagingDir,
}) async {
  await stagingDir.create(recursive: true);

  final input = InputFileStream(zipFile.path);
  final archive = ZipDecoder().decodeStream(input);

  for (final entry in archive) {
    final name = entry.name;
    final safeRel = _safeRelativePath(name);
    if (safeRel == null) {
      throw FormatException("Unsafe zip entry path: $name");
    }
    final targetPath = p.join(stagingDir.path, safeRel);

    if (entry.isFile) {
      final data = entry.content as List<int>;
      final file = File(targetPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data, flush: true);
    } else {
      await Directory(targetPath).create(recursive: true);
    }
  }

  return stagingDir;
}

Future<ApplyPlan> planApply({
  required Directory stagingDir,
  required Directory outDir,
}) async {
  final conflicts = <String>[];
  final filesToWrite = <String>[];

  if (!await outDir.exists()) {
    return ApplyPlan(
        conflicts: const [], filesToWrite: await _listFiles(stagingDir));
  }

  final stagingFiles = await _listFiles(stagingDir);
  for (final rel in stagingFiles) {
    final dest = File(p.join(outDir.path, rel));
    if (await dest.exists()) {
      conflicts.add(rel);
    } else {
      filesToWrite.add(rel);
    }
  }
  return ApplyPlan(
      conflicts: conflicts..sort(), filesToWrite: filesToWrite..sort());
}

Future<void> applyStaging({
  required Directory stagingDir,
  required Directory outDir,
  required bool force,
}) async {
  await outDir.create(recursive: true);
  final stagingFiles = await _listFiles(stagingDir);
  for (final rel in stagingFiles) {
    final src = File(p.join(stagingDir.path, rel));
    final dest = File(p.join(outDir.path, rel));
    if (await dest.exists()) {
      if (!force) {
        throw FileSystemException("Conflict: $rel");
      }
    }
    await dest.parent.create(recursive: true);
    await src.copy(dest.path);
  }
}

Future<List<String>> _listFiles(Directory dir) async {
  final out = <String>[];
  final base = dir.path;
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final rel = p.relative(entity.path, from: base);
      out.add(p.normalize(rel));
    }
  }
  out.sort();
  return out;
}

String? _safeRelativePath(String raw) {
  final normalized = p.normalize(raw).replaceAll("\\", "/");
  if (normalized.startsWith("/") || normalized.startsWith("~")) return null;
  final parts = p.split(normalized);
  if (parts.any((part) => part == "..")) return null;
  if (parts.isEmpty) return null;
  return p.joinAll(parts);
}
