import "dart:io";

import "package:flutterinit_cli/src/core/pubspec_sanitize.dart";
import "package:path/path.dart" as p;
import "package:test/test.dart";

void main() {
  test("sanitizePubspecDuplicates removes duplicate dependency keys", () async {
    final tmp = await Directory.systemTemp.createTemp("flutterinit_pubspec_");
    addTearDown(() => tmp.delete(recursive: true));

    final file = File(p.join(tmp.path, "pubspec.yaml"));
    await file.writeAsString("""
name: x
dependencies:
  flutter:
    sdk: flutter
  get: ^4.7.3
  get: ^4.7.3
dev_dependencies:
  test: ^1.0.0
  test: ^1.0.0
""");

    final result = await sanitizePubspecDuplicates(file);
    expect(result.changed, true);
    expect(result.removedKeys, containsAll(<String>["dependencies:get", "dev_dependencies:test"]));

    final out = await file.readAsString();
    expect(RegExp(r"^\s+get:\s", multiLine: true).allMatches(out).length, 1);
    expect(RegExp(r"^\s+test:\s", multiLine: true).allMatches(out).length, 1);
  });
}
