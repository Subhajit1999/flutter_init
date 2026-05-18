import "dart:io";

import "package:http/http.dart" as http;

import "../core/endpoints.dart";
import "../core/exit_codes.dart";

class DoctorCommand {
  DoctorCommand({required this.stdout, required this.stderr});

  final Stdout stdout;
  final Stdout stderr;

  Future<int> run({required bool verbose, required Uri endpoint}) async {
    final dartOk = await _check("dart", ["--version"], verbose: verbose);
    final flutterOk = await _check(
      "flutter",
      ["--version"],
      verbose: verbose,
      required: false,
    );

    if (!dartOk) return ExitCodes.unavailable;

    stdout.writeln("dart: ok");
    if (flutterOk) {
      stdout.writeln("flutter: ok");
    } else {
      stdout.writeln(
          "flutter: not found (pub get steps will be skipped unless flutter is installed)");
    }

    try {
      final url = resolveConfigEndpoint(endpoint);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        stdout.writeln("endpoint: ok ($url)");
      } else {
        stdout.writeln("endpoint: unavailable ($url) ${response.statusCode}");
      }
    } catch (e) {
      stdout.writeln("endpoint: unavailable ($endpoint) $e");
    }

    return ExitCodes.success;
  }

  Future<bool> _check(
    String exe,
    List<String> args, {
    required bool verbose,
    bool required = true,
  }) async {
    try {
      final result = await Process.run(exe, args, runInShell: true);
      if (verbose) {
        stdout.writeln(result.stdout);
        stderr.writeln(result.stderr);
      }
      return result.exitCode == 0;
    } catch (e) {
      if (required) {
        stderr.writeln("$exe not available: $e");
      }
      return false;
    }
  }
}
