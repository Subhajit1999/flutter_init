import "dart:io";

import "package:flutterinit_cli/src/core/gitignore_env.dart";
import "package:path/path.dart" as p;
import "package:test/test.dart";

void main() {
  test("updateGitignore removes platform ignores and adds .env", () async {
    final tmp = await Directory.systemTemp.createTemp("flutterinit_gitignore_");
    addTearDown(() => tmp.delete(recursive: true));

    final gitignore = File(p.join(tmp.path, ".gitignore"));
    await gitignore.writeAsString("""
.dart_tool/
build/
android/
ios/
web/
""");

    await updateGitignore(tmp, includeDotenv: true);
    final out = await gitignore.readAsString();
    expect(out.contains("android/"), false);
    expect(out.contains("ios/"), false);
    expect(out.contains("web/"), false);
    expect(out.contains(".env"), true);
  });

  test("projectUsesDotenv detects .env asset entry", () async {
    final tmp = await Directory.systemTemp.createTemp("flutterinit_dotenv_");
    addTearDown(() => tmp.delete(recursive: true));

    await File(p.join(tmp.path, "pubspec.yaml")).writeAsString("""
name: x
dependencies:
  flutter:
    sdk: flutter
  flutter_dotenv: ^6.0.0
flutter:
  assets:
    - .env
""");

    expect(await projectUsesDotenv(tmp), true);
  });
}

