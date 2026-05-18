import "dart:io";

import "package:path/path.dart" as p;

Directory defaultFlutterInitHome() {
  final home = Platform.environment["HOME"] ??
      Platform.environment["USERPROFILE"] ??
      Directory.current.path;
  return Directory(p.join(home, ".flutterinit"));
}

class CacheStore {
  CacheStore({Directory? baseDir}) : baseDir = baseDir ?? defaultFlutterInitHome();

  final Directory baseDir;

  Directory get cacheDir => Directory(p.join(baseDir.path, "cache"));

  Future<void> ensure() async {
    await cacheDir.create(recursive: true);
  }

  File zipForKey(String key) => File(p.join(cacheDir.path, "$key.zip"));
}
