import "package:path/path.dart" as p;

const supportedPlatforms = <String>{
  "android",
  "ios",
  "web",
  "macos",
  "windows",
  "linux",
};

List<String> parsePlatforms(String raw,
    {List<String> defaults = const ["android", "ios"]}) {
  final parts = raw
      .split(",")
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();
  final list = parts.isEmpty ? defaults : parts;
  final unique = <String>{};
  for (final p in list) {
    if (!supportedPlatforms.contains(p)) {
      throw FormatException("Unsupported platform: $p");
    }
    unique.add(p);
  }
  return unique.toList()..sort();
}

String deriveOrgFromPackageId(String packageId) {
  final parts = packageId.split(".").where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) return "${parts[0]}.${parts[1]}";
  return "com.example";
}

List<String> flutterCreateArgs({
  required String outDir,
  required String projectName,
  required String org,
  required String description,
  required List<String> platforms,
}) {
  final normalized = platforms.toList()..sort();
  return <String>[
    "create",
    p.normalize(outDir),
    "--project-name",
    projectName,
    "--org",
    org,
    "--description",
    description,
    "--platforms",
    normalized.join(","),
  ];
}
