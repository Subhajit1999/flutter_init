import "dart:convert";
import "dart:io";

import "package:path/path.dart" as p;

import "../core/cache_store.dart";
import "../core/exit_codes.dart";
import "../core/generator_client.dart";
import "../core/server_client.dart";
import "../core/zip_apply.dart";
import "../wizard/prompt.dart";
import "../wizard/wizard.dart";

class CreateCommand {
  CreateCommand({required this.stdout, required this.stderr, required this.stdin});

  final Stdout stdout;
  final Stdout stderr;
  final Stdin stdin;

  Future<int> run({
    required Uri endpoint,
    required Directory outDir,
    required bool force,
    required bool yes,
    required bool pubGet,
    required Directory? cacheDir,
  }) async {
    Directory? staging;
    try {
      final server = await ServerClient(endpoint: endpoint).fetchConfig();
      final wizard = Wizard(prompt: Prompt(stdout: stdout, stderr: stderr, stdin: stdin, yes: yes));
      final config = wizard.run(server);

      await outDir.create(recursive: true);
      final configFile = File(p.join(outDir.path, "flutterinit.json"));
      if (await configFile.exists() && !force) {
        stderr.writeln("flutterinit.json already exists in ${outDir.path}. Use --force to overwrite.");
        return ExitCodes.io;
      }

      final encoder = const JsonEncoder.withIndent("  ");
      await configFile.writeAsString("${encoder.convert({
            "\$schema": "flutterinit",
            "generatorVersion": server.generatorVersion,
            "config": config,
          })}\n");

      final client = GeneratorClient(endpoint: endpoint, cache: CacheStore(baseDir: cacheDir));
      final zip = await client.generateZip(config: config, fonts: const []);

      staging = await Directory.systemTemp.createTemp("flutterinit_staging_");
      await extractZipToStaging(zipFile: zip, stagingDir: staging);
      final plan = await planApply(stagingDir: staging, outDir: outDir);

      if (plan.conflicts.isNotEmpty && !force) {
        stderr.writeln("Conflicts (${plan.conflicts.length}). Use --force to overwrite:");
        for (final c in plan.conflicts.take(25)) {
          stderr.writeln("  $c");
        }
        if (plan.conflicts.length > 25) {
          stderr.writeln("  ...and ${plan.conflicts.length - 25} more");
        }
        return ExitCodes.io;
      }

      await applyStaging(stagingDir: staging, outDir: outDir, force: true);
      stdout.writeln("Generated project at ${p.normalize(outDir.path)}");

      if (pubGet) {
        final flutterOk = await _flutterAvailable();
        if (!flutterOk) {
          stderr.writeln("flutter not found; skipping flutter pub get.");
        } else {
          final result = await Process.run(
            "flutter",
            ["pub", "get"],
            workingDirectory: outDir.path,
            runInShell: true,
          );
          stdout.write(result.stdout);
          stderr.write(result.stderr);
          if (result.exitCode != 0) {
            return ExitCodes.software;
          }
        }
      }

      return ExitCodes.success;
    } catch (e) {
      stderr.writeln("create failed: $e");
      return ExitCodes.software;
    } finally {
      await staging?.delete(recursive: true);
    }
  }

  Future<bool> _flutterAvailable() async {
    try {
      final result = await Process.run("flutter", ["--version"], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
