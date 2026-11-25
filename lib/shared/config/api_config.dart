class ApiConfig {
  ApiConfig(String value) : baseUri = Uri.parse(value) {
    if (!['http', 'https'].contains(baseUri.scheme) ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        (baseUri.path.isNotEmpty && baseUri.path != '/')) {
      throw ArgumentError('API_BASE_URL должен быть HTTP(S) адресом без пути.');
    }
  }
  final Uri baseUri;
  Uri endpoint(String path) => baseUri.resolve(path);
}
