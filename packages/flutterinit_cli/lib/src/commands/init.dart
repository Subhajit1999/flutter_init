import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as p;

import "../core/endpoints.dart";
import "../core/exit_codes.dart";
import "../core/server_config.dart";

class InitCommand {
  InitCommand({required this.stdout, required this.stderr});

  final Stdout stdout;
  final Stdout stderr;

  Future<int> run({
    required Uri endpoint,
    required Directory outDir,
    required bool force,
  }) async {
    try {
      final configUrl = resolveConfigEndpoint(endpoint);
      final response = await http.get(configUrl);
      if (response.statusCode != 200) {
        stderr.writeln("Failed to fetch defaults: ${response.statusCode}");
        stderr.writeln(response.body);
        return ExitCodes.unavailable;
      }

      final serverConfig = ServerConfig.fromJson(response.body);

      await outDir.create(recursive: true);
      final file = File(p.join(outDir.path, "flutterinit.json"));
      if (await file.exists() && !force) {
        stderr.writeln("flutterinit.json already exists. Use --force to overwrite.");
        return ExitCodes.io;
      }

      final payload = <String, dynamic>{
        "\$schema": "flutterinit",
        "generatorVersion": serverConfig.generatorVersion,
        "config": serverConfig.defaultConfig,
      };

      final encoder = const JsonEncoder.withIndent("  ");
      await file.writeAsString("${encoder.convert(payload)}\n");
      stdout.writeln("Wrote ${file.path}");
      return ExitCodes.success;
    } catch (e) {
      stderr.writeln("init failed: $e");
      return ExitCodes.software;
    }
  }
}
