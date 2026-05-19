import "dart:convert";
import "dart:io";

import "package:path/path.dart" as p;

import "../core/cache_store.dart";
import "../core/assets_from_pubspec.dart";
import "../core/exit_codes.dart";
import "../core/fs_copy.dart";
import "../core/gitignore_env.dart";
import "../core/generator_client.dart";
import "../core/platforms.dart";
import "../core/pubspec_sanitize.dart";
import "../core/server_client.dart";
import "../core/zip_apply.dart";
import "../wizard/prompt.dart";
import "../wizard/wizard.dart";

class CreateCommand {
  CreateCommand(
      {required this.stdout, required this.stderr, required this.stdin});

  final Stdout stdout;
  final Stdout stderr;
  final Stdin stdin;

  Future<int> run({
    required Uri endpoint,
    required Directory outDir,
    required bool force,
    required bool yes,
    required bool pubGet,
    required String platformsRaw,
    required Directory? cacheDir,
  }) async {
    Directory? staging;
    Directory? flutterSeed;

    try {
      final server = await ServerClient(endpoint: endpoint).fetchConfig();
      if (server.generatorVersion == "bundled") {
        stderr.writeln(
            "Using bundled defaults (server /api/config not available).");
      }

      final wizard = Wizard(
        prompt: Prompt(stdout: stdout, stderr: stderr, stdin: stdin, yes: yes),
      );
      final result = wizard.run(server, defaultPlatformsRaw: platformsRaw);
      final config = result.config;
      final platforms = result.platforms;
      stderr.writeln("Platforms: ${platforms.join(", ")}");

      await outDir.create(recursive: true);
      final configFile = File(p.join(outDir.path, "flutterinit.json"));
      if (await configFile.exists() && !force) {
        stderr.writeln(
            "flutterinit.json already exists in ${outDir.path}. Use --force to overwrite.");
        return ExitCodes.io;
      }

      final flutterOk = await _flutterAvailable();
      if (!flutterOk) {
        stderr.writeln("flutter not found; cannot generate platform folders.");
        return ExitCodes.unavailable;
      }

      flutterSeed =
          await Directory.systemTemp.createTemp("flutterinit_flutter_");
      final packageId = (config["packageId"] as String?) ?? "com.example.app";
      final org = deriveOrgFromPackageId(packageId);
      final projectName =
          (config["appName"] as String?) ?? p.basename(outDir.path);
      final description = (config["description"] as String?) ?? "";

      final args = flutterCreateArgs(
        outDir: flutterSeed.path,
        projectName: projectName,
        org: org,
        description: description,
        platforms: platforms,
      );

      final flutterCreate =
          await Process.run("flutter", args, runInShell: true);
      stdout.write(flutterCreate.stdout);
      stderr.write(flutterCreate.stderr);
      if (flutterCreate.exitCode != 0) {
        return ExitCodes.software;
      }

      final encoder = const JsonEncoder.withIndent("  ");
      await configFile.writeAsString("${encoder.convert({
            "\$schema": "flutterinit",
            "generatorVersion": server.generatorVersion,
            "cli": {"platforms": platforms},
            "config": config,
          })}\n");

      final metadata = File(p.join(flutterSeed.path, ".metadata"));
      if (await metadata.exists()) {
        await metadata.copy(p.join(outDir.path, ".metadata"));
      }

      for (final platform in platforms) {
        final src = Directory(p.join(flutterSeed.path, platform));
        if (!await src.exists()) continue;
        final dest = Directory(p.join(outDir.path, platform));
        if (await dest.exists() && force) {
          await dest.delete(recursive: true);
        }
        if (!await dest.exists()) {
          await copyDirectory(src, dest);
        }
      }

      final client = GeneratorClient(
          endpoint: endpoint, cache: CacheStore(baseDir: cacheDir));
      final zip = await client.generateZip(
        config: config,
        fonts: const [],
        cacheSalt: server.generatorVersion,
      );

      staging = await Directory.systemTemp.createTemp("flutterinit_staging_");
      await extractZipToStaging(zipFile: zip, stagingDir: staging);
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

      await applyStaging(stagingDir: staging, outDir: outDir, force: force);
      stdout.writeln("Generated project at ${p.normalize(outDir.path)}");

      final sanitize = await sanitizePubspecDuplicates(
          File(p.join(outDir.path, "pubspec.yaml")));
      if (sanitize.changed) {
        stderr.writeln(
            "Fixed duplicate keys in pubspec.yaml (${sanitize.removedKeys.join(", ")}).");
      }

      final assetsResult = await ensureAssetsFromPubspec(outDir);
      if (assetsResult.createdDirs.isNotEmpty) {
        stderr.writeln(
            "Created asset dirs: ${assetsResult.createdDirs.join(", ")}");
      }

      final usesDotenv = await projectUsesDotenv(outDir);
      await updateGitignore(outDir, includeDotenv: usesDotenv);
      if (usesDotenv) {
        await ensureEnvFile(outDir);
      }

      if (pubGet) {
        final pubGetResult = await Process.run(
          "flutter",
          ["pub", "get"],
          workingDirectory: outDir.path,
          runInShell: true,
        );
        stdout.write(pubGetResult.stdout);
        stderr.write(pubGetResult.stderr);
        if (pubGetResult.exitCode != 0) {
          return ExitCodes.software;
        }
      }

      return ExitCodes.success;
    } catch (e) {
      stderr.writeln("create failed: $e");
      return ExitCodes.software;
    } finally {
      await staging?.delete(recursive: true);
      await flutterSeed?.delete(recursive: true);
    }
  }

  Future<bool> _flutterAvailable() async {
    try {
      final result =
          await Process.run("flutter", ["--version"], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
