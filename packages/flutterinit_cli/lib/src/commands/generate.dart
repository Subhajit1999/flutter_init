import "dart:io";

import "../core/cache_store.dart";
import "../core/config_file.dart";
import "../core/exit_codes.dart";
import "../core/generator_client.dart";

class GenerateCommand {
  GenerateCommand({required this.stdout, required this.stderr});

  final Stdout stdout;
  final Stdout stderr;

  Future<int> run({
    required Uri endpoint,
    required File configFile,
    required File? outZip,
    required Directory? cacheDir,
    required bool verbose,
  }) async {
    try {
      if (!await configFile.exists()) {
        stderr.writeln("Config not found: ${configFile.path}");
        return ExitCodes.data;
      }

      final cfg = await ConfigFile.read(configFile);
      final client = GeneratorClient(
          endpoint: endpoint, cache: CacheStore(baseDir: cacheDir));

      final zip = await client.generateZip(
        config: cfg.config,
        fonts: const [],
        cacheSalt: cfg.generatorVersion ?? "",
        outZip: outZip,
        verbose: verbose,
      );
      stdout.writeln(zip.path);
      return ExitCodes.success;
    } catch (e) {
      stderr.writeln("generate failed: $e");
      return ExitCodes.software;
    }
  }
}
