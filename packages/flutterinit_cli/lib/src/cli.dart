import "dart:io";

import "package:args/args.dart";

import "commands/apply.dart";
import "commands/create.dart";
import "commands/doctor.dart";
import "commands/generate.dart";
import "commands/init.dart";
import "core/exit_codes.dart";

class Cli {
  Cli({required this.stdout, required this.stderr, required this.stdin});

  final Stdout stdout;
  final Stdout stderr;
  final Stdin stdin;

  Future<int> run(List<String> args) async {
    final parser = _buildParser();

    ArgResults parsed;
    try {
      parsed = parser.parse(args);
    } on ArgParserException catch (e) {
      stderr.writeln(e.message);
      stderr.writeln(usageText(parser));
      return ExitCodes.usage;
    }

    if (parsed["help"] == true) {
      stdout.writeln(usageText(parser));
      return ExitCodes.success;
    }

    if (parsed["version"] == true) {
      stdout.writeln("flutterinit_cli 0.1.0");
      return ExitCodes.success;
    }

    final command = parsed.command;
    if (command == null) {
      stdout.writeln(usageText(parser));
      return ExitCodes.usage;
    }

    final endpoint = Uri.parse(command["endpoint"] as String);
    final cacheDir = command["cache-dir"] as String?;
    final verbose = command["verbose"] as bool;

    switch (command.name) {
      case "doctor":
        return DoctorCommand(stdout: stdout, stderr: stderr)
            .run(verbose: verbose, endpoint: endpoint);
      case "init":
        return InitCommand(stdout: stdout, stderr: stderr).run(
          endpoint: endpoint,
          outDir: Directory(command["out"] as String),
          force: command["force"] as bool,
        );
      case "create":
        final rest = command.rest;
        if (rest.isEmpty) {
          stderr.writeln("Missing project directory name.");
          stderr.writeln(usageText(parser));
          return ExitCodes.usage;
        }
        final out = Directory(rest.first);
        return CreateCommand(stdout: stdout, stderr: stderr, stdin: stdin).run(
          endpoint: endpoint,
          outDir: out,
          force: command["force"] as bool,
          yes: command["yes"] as bool,
          pubGet: command["pub-get"] as bool,
          platformsRaw: command["platforms"] as String,
          cacheDir: cacheDir != null ? Directory(cacheDir) : null,
        );
      case "generate":
        final configPath = command["config"] as String?;
        if (configPath == null) {
          stderr.writeln("Missing --config.");
          return ExitCodes.usage;
        }
        return GenerateCommand(stdout: stdout, stderr: stderr).run(
          endpoint: endpoint,
          configFile: File(configPath),
          outZip: command["out-zip"] != null
              ? File(command["out-zip"] as String)
              : null,
          cacheDir: cacheDir != null ? Directory(cacheDir) : null,
          verbose: verbose,
        );
      case "apply":
        final zipPath = command["zip"] as String?;
        final outPath = command["out"] as String?;
        if (zipPath == null || outPath == null) {
          stderr.writeln("Missing --zip or --out.");
          return ExitCodes.usage;
        }
        return ApplyCommand(stdout: stdout, stderr: stderr).run(
          zipFile: File(zipPath),
          outDir: Directory(outPath),
          force: command["force"] as bool,
          dryRun: command["dry-run"] as bool,
        );
      default:
        stderr.writeln("Unknown command: ${command.name}");
        return ExitCodes.usage;
    }
  }

  ArgParser _buildParser() {
    final parser = ArgParser()..addFlag("help", abbr: "h", negatable: false);
    parser.addFlag("version", negatable: false);

    parser.addCommand("doctor")
      ..addFlag("verbose", defaultsTo: false)
      ..addOption("endpoint",
          defaultsTo: "https://flutterinit.com/api/generate")
      ..addOption("cache-dir");

    parser.addCommand("init")
      ..addOption("out", abbr: "o", defaultsTo: ".")
      ..addFlag("force", defaultsTo: false)
      ..addOption("endpoint",
          defaultsTo: "https://flutterinit.com/api/generate")
      ..addOption("cache-dir")
      ..addFlag("verbose", defaultsTo: false);

    parser.addCommand("create")
      ..addFlag("yes", abbr: "y", defaultsTo: false)
      ..addFlag("force", defaultsTo: false)
      ..addFlag("pub-get", defaultsTo: true)
      ..addOption("platforms", defaultsTo: "android,ios")
      ..addOption("endpoint",
          defaultsTo: "https://flutterinit.com/api/generate")
      ..addOption("cache-dir")
      ..addFlag("verbose", defaultsTo: false);

    parser.addCommand("generate")
      ..addOption("config", abbr: "c")
      ..addOption("out-zip")
      ..addOption("endpoint",
          defaultsTo: "https://flutterinit.com/api/generate")
      ..addOption("cache-dir")
      ..addFlag("verbose", defaultsTo: false);

    parser.addCommand("apply")
      ..addOption("zip")
      ..addOption("out", abbr: "o")
      ..addFlag("force", defaultsTo: false)
      ..addFlag("dry-run", defaultsTo: false)
      ..addOption("endpoint",
          defaultsTo: "https://flutterinit.com/api/generate")
      ..addOption("cache-dir")
      ..addFlag("verbose", defaultsTo: false);

    return parser;
  }
}

String usageText(ArgParser parser) {
  final buffer = StringBuffer();
  buffer.writeln("flutterinit <command> [options]");
  buffer.writeln("");
  buffer.writeln("Commands:");
  buffer.writeln("  doctor             Check local environment.");
  buffer.writeln(
      "  init               Write flutterinit.json using server defaults.");
  buffer.writeln(
      "  create <dir>       Run interactive wizard and generate project.");
  buffer.writeln("  generate           Download ZIP from config.");
  buffer.writeln("  apply              Extract ZIP into folder.");
  buffer.writeln("");
  buffer.writeln(parser.usage);
  return buffer.toString();
}
