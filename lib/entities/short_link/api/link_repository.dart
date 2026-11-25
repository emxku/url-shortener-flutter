import 'dart:convert';
import 'dart:typed_data';

import '../../../shared/api/api_client.dart';
import '../model/short_link.dart';

abstract interface class LinkRepository {
  Future<ShortLink> create(String url);
  Future<void> delete(String code);
  Future<Uint8List> qr(String code);
}

class HttpLinkRepository implements LinkRepository {
  HttpLinkRepository(this.api);
  final ApiClient api;
  @override
  Future<ShortLink> create(String url) async {
    final response = await api.request(
      'POST',
      '/api/v1/shorten',
      body: {'url': url},
    );
    try {
      return ShortLink.fromJson({
        ...jsonDecode(response.body) as Map<String, dynamic>,
        'original_url': url,
      });
    } on Object {
      throw const ApiException('Сервер вернул некорректный результат.');
    }
  }

  @override
  Future<void> delete(String code) async {
    try {
      await api.request('DELETE', '/${Uri.encodeComponent(code)}');
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
    }
  }

  @override
  Future<Uint8List> qr(String code) async {
    final response = await api.request(
      'GET',
      '/${Uri.encodeComponent(code)}/qr',
    );
    return response.bodyBytes;
  }
}
