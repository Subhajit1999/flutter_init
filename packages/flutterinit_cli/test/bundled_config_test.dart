import "package:flutterinit_cli/src/core/bundled_server_config.dart";
import "package:test/test.dart";

void main() {
  test("bundledServerConfig has expected shape", () {
    final cfg = bundledServerConfig();
    expect(cfg.generatorVersion, "bundled");
    expect(cfg.defaultConfig["appName"], isA<String>());
    expect(cfg.defaultConfig["packageId"], isA<String>());
    expect(cfg.options["architectureOptions"], isA<List>());
    expect(cfg.stepOrder, containsAll(<String>["basics", "generate"]));
  });
}
