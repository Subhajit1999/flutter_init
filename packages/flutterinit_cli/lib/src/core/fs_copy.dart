import "dart:io";

import "package:path/path.dart" as p;

Future<void> copyDirectory(Directory source, Directory dest) async {
  await dest.create(recursive: true);
  await for (final entity in source.list(recursive: false, followLinks: false)) {
    final name = p.basename(entity.path);
    final targetPath = p.join(dest.path, name);
    if (entity is Directory) {
      await copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      await File(targetPath).parent.create(recursive: true);
      await entity.copy(targetPath);
    }
  }
}
