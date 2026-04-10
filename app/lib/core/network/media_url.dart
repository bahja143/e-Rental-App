import 'api_config.dart';

class MediaUrl {
  MediaUrl._();

  static const List<String> _publicAssetPrefixes = <String>[
    '/uploads/',
    '/listing-images/',
  ];

  static String normalize(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return '';

    final parsed = Uri.tryParse(raw);
    if (parsed == null) return raw;

    if (!parsed.hasScheme) {
      final path = raw.startsWith('/') ? raw : '/$raw';
      if (_isPublicAssetPath(path)) {
        return _publicBaseUri().resolve(path).toString();
      }
      return raw;
    }

    if (_isPublicAssetPath(parsed.path)) {
      return _publicBaseUri()
          .replace(
            path: parsed.path,
            query: parsed.hasQuery ? parsed.query : null,
            fragment: parsed.fragment.isEmpty ? null : parsed.fragment,
          )
          .toString();
    }

    return raw;
  }

  static bool _isPublicAssetPath(String path) {
    return _publicAssetPrefixes.any(path.startsWith);
  }

  static Uri _publicBaseUri() {
    final apiUri = Uri.parse(ApiConfig.baseUrl);
    if (apiUri.hasPort) {
      return Uri(
        scheme: apiUri.scheme,
        host: apiUri.host,
        port: apiUri.port,
      );
    }
    return Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
    );
  }
}
