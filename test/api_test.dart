import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:url_shortener/shared/api/api_client.dart';
import 'package:url_shortener/shared/config/api_config.dart';
import 'package:url_shortener/entities/short_link/api/link_repository.dart';

void main() {
  test('Create matches Go contract and preserves URL case', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/shorten');
      expect(jsonDecode(request.body), {
        'url': 'https://example.com/AbC?Token=X',
      });
      return http.Response(
        '{"short_url":"http://localhost:8080/aB12","expires_at":0,"click_count":2}',
        201,
      );
    });
    final repository = HttpLinkRepository(
      ApiClient(client, ApiConfig('http://localhost:8080')),
    );
    final link = await repository.create('https://example.com/AbC?Token=X');
    expect(link.code, 'aB12');
    expect(link.expiresAt, null);
    expect(link.clickCount, 2);
  });
  test('404 delete is idempotent; QR uses configured API origin', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.test');
      if (request.method == 'DELETE') return http.Response('', 404);
      expect(request.url.path, '/abc/qr');
      return http.Response.bytes([137, 80, 78, 71], 200);
    });
    final repository = HttpLinkRepository(
      ApiClient(client, ApiConfig('https://api.test')),
    );
    await repository.delete('abc');
    expect(await repository.qr('abc'), [137, 80, 78, 71]);
  });
  test(
    'Malformed responses and rate limiting become readable errors',
    () async {
      for (final status in [201, 429, 500]) {
        final repository = HttpLinkRepository(
          ApiClient(
            MockClient((_) async => http.Response('invalid', status)),
            ApiConfig('https://api.test'),
          ),
        );
        await expectLater(
          repository.create('https://example.com'),
          throwsA(isA<ApiException>()),
        );
      }
    },
  );
}
