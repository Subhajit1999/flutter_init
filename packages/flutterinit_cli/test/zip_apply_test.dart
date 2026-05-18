import "dart:io";

import "package:archive/archive.dart";
import "package:flutterinit_cli/src/core/zip_apply.dart";
import "package:path/path.dart" as p;
import "package:test/test.dart";

void main() {
  test("extractZipToStaging writes files", () async {
    final tmp = await Directory.systemTemp.createTemp("flutterinit_test_");
    addTearDown(() => tmp.delete(recursive: true));

    final zipFile = File(p.join(tmp.path, "out.zip"));
    final archive = Archive()
      ..addFile(ArchiveFile("lib/main.dart", 5, "hello".codeUnits))
      ..addFile(ArchiveFile("pubspec.yaml", 3, "a:1".codeUnits));

    final bytes = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(bytes!, flush: true);

    final staging = Directory(p.join(tmp.path, "staging"));
    await extractZipToStaging(zipFile: zipFile, stagingDir: staging);

    expect(await File(p.join(staging.path, "lib", "main.dart")).readAsString(), "hello");
    expect(await File(p.join(staging.path, "pubspec.yaml")).exists(), true);
  });

  test("extractZipToStaging rejects zip slip paths", () async {
    final tmp = await Directory.systemTemp.createTemp("flutterinit_test_");
    addTearDown(() => tmp.delete(recursive: true));

    final zipFile = File(p.join(tmp.path, "evil.zip"));
    final archive = Archive()..addFile(ArchiveFile("../evil.txt", 1, "x".codeUnits));
    final bytes = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(bytes!, flush: true);

    final staging = Directory(p.join(tmp.path, "staging"));
    expect(
      () async => extractZipToStaging(zipFile: zipFile, stagingDir: staging),
      throwsA(isA<FormatException>()),
    );
  });

  test("planApply detects conflicts", () async {
    final tmp = await Directory.systemTemp.createTemp("flutterinit_test_");
    addTearDown(() => tmp.delete(recursive: true));

    final staging = Directory(p.join(tmp.path, "staging"));
    await staging.create(recursive: true);
    await File(p.join(staging.path, "a.txt")).writeAsString("a");
    await Directory(p.join(staging.path, "lib")).create(recursive: true);
    await File(p.join(staging.path, "lib", "b.txt")).writeAsString("b");

    final outDir = Directory(p.join(tmp.path, "out"));
    await outDir.create(recursive: true);
    await File(p.join(outDir.path, "a.txt")).writeAsString("old");

    final plan = await planApply(stagingDir: staging, outDir: outDir);
    expect(plan.conflicts, ["a.txt"]);
    expect(plan.filesToWrite, ["lib/b.txt"]);
  });
}
