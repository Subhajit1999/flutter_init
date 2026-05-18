import "dart:io";

const _platformIgnoreLines = <String>{
  "android/",
  "ios/",
  "web/",
  "macos/",
  "windows/",
  "linux/",
};

Future<void> ensureEnvFile(Directory projectDir) async {
  final env = File("${projectDir.path}/.env");
  if (!await env.exists()) {
    await env.writeAsString("\n");
  }
}

Future<void> updateGitignore(Directory projectDir, {required bool includeDotenv}) async {
  final gitignore = File("${projectDir.path}/.gitignore");
  final lines = await gitignore.exists() ? await gitignore.readAsLines() : <String>[];

  final out = <String>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (_platformIgnoreLines.contains(trimmed)) {
      continue;
    }
    out.add(line);
  }

  if (includeDotenv) {
    final hasEnv = out.any((l) => l.trim() == ".env");
    if (!hasEnv) {
      if (out.isNotEmpty && out.last.trim().isNotEmpty) out.add("");
      out.add(".env");
    }
  }

  await gitignore.writeAsString("${out.join("\n")}\n");
}

Future<bool> projectUsesDotenv(Directory projectDir) async {
  final pubspec = File("${projectDir.path}/pubspec.yaml");
  if (!await pubspec.exists()) return false;
  final content = await pubspec.readAsString();
  if (RegExp(r"^\s+-\s+\.env\s*$", multiLine: true).hasMatch(content)) return true;
  if (RegExp(r"^\s+flutter_dotenv:\s", multiLine: true).hasMatch(content)) return true;
  return false;
}
