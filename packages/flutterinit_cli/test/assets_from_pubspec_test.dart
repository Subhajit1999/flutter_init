import "dart:io";

import "package:flutterinit_cli/src/core/assets_from_pubspec.dart";
import "package:path/path.dart" as p;
import "package:test/test.dart";

void main() {
  test("ensureAssetsFromPubspec creates declared asset directories and .env", () async {
    final tmp = await Directory.systemTemp.createTemp("flutterinit_assets_");
    addTearDown(() => tmp.delete(recursive: true));

    await File(p.join(tmp.path, "pubspec.yaml")).writeAsString("""
name: x
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - assets/
    - assets/images/
    - assets/icons/
    - .env
""");

    final result = await ensureAssetsFromPubspec(tmp);
    expect(result.createdEnv, true);
    expect(await Directory(p.join(tmp.path, "assets")).exists(), true);
    expect(await Directory(p.join(tmp.path, "assets", "images")).exists(), true);
    expect(await Directory(p.join(tmp.path, "assets", "icons")).exists(), true);
    expect(await File(p.join(tmp.path, ".env")).exists(), true);
  });
}

