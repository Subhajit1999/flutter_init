import "package:flutterinit_cli/src/core/validators.dart";
import "package:test/test.dart";

void main() {
  test("isValidAppName", () {
    expect(isValidAppName("flutter_starter"), true);
    expect(isValidAppName("FlutterStarter"), false);
    expect(isValidAppName("_bad"), false);
    expect(isValidAppName("bad-name"), false);
  });

  test("isValidPackageId", () {
    expect(isValidPackageId("com.example.app"), true);
    expect(isValidPackageId("com.example.app_name"), true);
    expect(isValidPackageId("com..example.app"), false);
    expect(isValidPackageId("Com.example.app"), false);
  });

  test("derivePackageId", () {
    expect(derivePackageId("flutter_starter"), "com.example.flutter_starter");
    expect(derivePackageId(""), "com.example.app");
    expect(derivePackageId("bad-name"), "com.example.bad_name");
  });
}
