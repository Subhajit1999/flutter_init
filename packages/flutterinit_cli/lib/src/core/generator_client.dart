import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:http_parser/http_parser.dart";
import "package:path/path.dart" as p;

import "cache_store.dart";
import "endpoints.dart";
import "hash.dart";

class GeneratorClient {
  GeneratorClient({required Uri endpoint, CacheStore? cache})
      : generateUrl = resolveGenerateEndpoint(endpoint),
        cache = cache ?? CacheStore();

  final Uri generateUrl;
  final CacheStore cache;

  Future<File> generateZip({
    required Map<String, dynamic> config,
    required List<File> fonts,
    File? outZip,
    bool verbose = false,
  }) async {
    final cacheKey = await _cacheKey(config: config, fonts: fonts);
    await cache.ensure();
    final cached = cache.zipForKey(cacheKey);
    if (await cached.exists()) {
      if (outZip != null) {
        await outZip.parent.create(recursive: true);
        await cached.copy(outZip.path);
        return outZip;
      }
      return cached;
    }

    final request = http.MultipartRequest("POST", generateUrl);
    request.fields["config"] = jsonEncode(config);

    for (final font in fonts) {
      final fileName = p.basename(font.path);
      request.files.add(await http.MultipartFile.fromPath(
        "font",
        font.path,
        filename: fileName,
        contentType: MediaType("application", "octet-stream"),
      ));
    }

    final streamed = await request.send();
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw HttpException("Generate failed: ${streamed.statusCode} $body", uri: generateUrl);
    }

    final target = outZip ?? cached;
    await target.parent.create(recursive: true);

    final sink = target.openWrite();
    await streamed.stream.pipe(sink);
    await sink.close();

    if (outZip != null) {
      await target.copy(cached.path);
      if (verbose) {
        stderr.writeln("Cached ZIP at ${cached.path}");
      }
    }

    return target;
  }

  Future<String> _cacheKey({
    required Map<String, dynamic> config,
    required List<File> fonts,
  }) async {
    final configJson = jsonEncode(config);
    final fontSig = <String>[];
    for (final f in fonts) {
      final stat = await f.stat();
      fontSig.add("${p.basename(f.path)}:${stat.size}:${stat.modified.millisecondsSinceEpoch}");
    }
    fontSig.sort();
    return sha256Hex("$configJson|${fontSig.join("|")}");
  }
}
