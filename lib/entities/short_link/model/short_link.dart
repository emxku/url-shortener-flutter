class ShortLink {
  const ShortLink({
    required this.originalUrl,
    required this.shortUrl,
    required this.expiresAt,
    required this.clickCount,
  });
  final String originalUrl;
  final String shortUrl;
  final DateTime? expiresAt;
  final int clickCount;
  String get code => Uri.parse(shortUrl).pathSegments.last;
  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
  factory ShortLink.fromJson(Map<String, dynamic> json) {
    final shortUrl = json['short_url'] as String;
    final uri = Uri.parse(shortUrl);
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.pathSegments.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(uri.pathSegments.last)) {
      throw const FormatException('Invalid short URL');
    }
    final expires = json['expires_at'] as int;
    return ShortLink(
      originalUrl: json['original_url'] as String,
      shortUrl: shortUrl,
      expiresAt: expires == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expires * 1000),
      clickCount: json['click_count'] as int,
    );
  }
  Map<String, dynamic> toJson() => {
    'original_url': originalUrl,
    'short_url': shortUrl,
    'expires_at': (expiresAt?.millisecondsSinceEpoch ?? 0) ~/ 1000,
    'click_count': clickCount,
  };
}
