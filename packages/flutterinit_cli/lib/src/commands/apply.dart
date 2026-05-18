import "dart:io";

import "package:path/path.dart" as p;

import "../core/exit_codes.dart";
import "../core/pubspec_sanitize.dart";
import "../core/zip_apply.dart";

class ApplyCommand {
  ApplyCommand({required this.stdout, required this.stderr});

  final Stdout stdout;
  final Stdout stderr;

  Future<int> run({
    required File zipFile,
    required Directory outDir,
    required bool force,
    required bool dryRun,
  }) async {
    Directory? staging;
    try {
      if (!await zipFile.exists()) {
        stderr.writeln("ZIP not found: ${zipFile.path}");
        return ExitCodes.data;
      }

      staging = await Directory.systemTemp.createTemp("flutterinit_staging_");
      await extractZipToStaging(zipFile: zipFile, stagingDir: staging);
      final plan = await planApply(stagingDir: staging, outDir: outDir);

      if (plan.conflicts.isNotEmpty && !force) {
        stderr.writeln(
            "Conflicts (${plan.conflicts.length}). Use --force to overwrite:");
        for (final c in plan.conflicts.take(25)) {
          stderr.writeln("  $c");
        }
        if (plan.conflicts.length > 25) {
          stderr.writeln("  ...and ${plan.conflicts.length - 25} more");
        }
        return ExitCodes.io;
      }

      if (dryRun) {
        stdout.writeln(
            "Dry run: would write ${plan.filesToWrite.length + plan.conflicts.length} files into ${p.normalize(outDir.path)}");
        return ExitCodes.success;
      }

      await applyStaging(stagingDir: staging, outDir: outDir, force: force);
      final result = await sanitizePubspecDuplicates(
          File(p.join(outDir.path, "pubspec.yaml")));
      if (result.changed) {
        stderr.writeln(
            "Fixed duplicate keys in pubspec.yaml (${result.removedKeys.join(", ")}).");
      }
      stdout.writeln("Wrote files into ${p.normalize(outDir.path)}");
      return ExitCodes.success;
    } catch (e) {
      stderr.writeln("apply failed: $e");
      return ExitCodes.software;
    } finally {
      await staging?.delete(recursive: true);
    }
  }
}
