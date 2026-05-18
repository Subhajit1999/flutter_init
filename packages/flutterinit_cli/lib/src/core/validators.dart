final _appNameRe = RegExp(r"^[a-z][a-z0-9_]*$");
final _packageIdRe = RegExp(r"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$");

bool isValidAppName(String value) => _appNameRe.hasMatch(value);
bool isValidPackageId(String value) => _packageIdRe.hasMatch(value);

String derivePackageId(String appName) {
  final cleaned = appName
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9_]"), "_")
      .replaceAll(RegExp(r"_+"), "_")
      .replaceAll(RegExp(r"^_+|_+$"), "");
  if (cleaned.isEmpty) return "com.example.app";
  return "com.example.$cleaned";
}
