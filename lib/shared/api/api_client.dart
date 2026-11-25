import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.client, this.config);
  final http.Client client;
  final ApiConfig config;
  Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, config.endpoint(path));
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await (() async {
        return http.Response.fromStream(await client.send(request));
      })().timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw ApiException(switch (response.statusCode) {
        400 => 'Сервер отклонил ссылку. Проверьте адрес.',
        404 => 'Ссылка не найдена.',
        410 => 'Срок действия ссылки истёк.',
        429 => 'Слишком много запросов. Попробуйте позже.',
        _ => 'Ошибка сервера. Попробуйте позже.',
      }, response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'Сервер не ответил вовремя. Результат операции неизвестен.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Не удалось связаться с сервером. Проверьте подключение.',
      );
    }
  }
}
