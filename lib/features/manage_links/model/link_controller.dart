import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../entities/short_link/short_link.dart';
import '../../../shared/api/api_client.dart';

final linkRepositoryProvider = Provider<LinkRepository>(
  (ref) => throw UnimplementedError(),
);
final linkHistoryProvider = Provider<LinkHistory>(
  (ref) => throw UnimplementedError(),
);
final linkControllerProvider = NotifierProvider<LinkController, LinksState>(
  LinkController.new,
);

class LinksState {
  const LinksState({
    this.links = const [],
    this.loading = true,
    this.busy = false,
    this.error,
  });
  final List<ShortLink> links;
  final bool loading;
  final bool busy;
  final String? error;
}

String? validateUrl(String? value) {
  final text = value?.trim() ?? '';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      RegExp(r'\s').hasMatch(text)) {
    return 'Введите полный адрес, например https://example.com';
  }
  return null;
}

class LinkController extends Notifier<LinksState> {
  @override
  LinksState build() {
    Future.microtask(load);
    return const LinksState();
  }

  Future<void> load() async {
    try {
      final links = await ref.read(linkHistoryProvider).load();
      if (ref.mounted) state = LinksState(links: links, loading: false);
    } on Object {
      if (ref.mounted) {
        state = const LinksState(
          loading: false,
          error: 'Не удалось прочитать историю на устройстве.',
        );
      }
    }
  }

  Future<void> create(String url) async {
    if (state.busy || state.loading) return;
    final error = validateUrl(url);
    if (error != null) {
      state = LinksState(links: state.links, loading: false, error: error);
      return;
    }
    await _change(() async {
      final link = await ref.read(linkRepositoryProvider).create(url.trim());
      return [
        link,
        ...state.links.where((item) => item.shortUrl != link.shortUrl),
      ];
    });
  }

  Future<void> delete(ShortLink link) async {
    if (state.busy || state.loading) return;
    await _change(() async {
      await ref.read(linkRepositoryProvider).delete(link.code);
      return state.links
          .where((item) => item.shortUrl != link.shortUrl)
          .toList();
    });
  }

  Future<void> _change(Future<List<ShortLink>> Function() operation) async {
    state = LinksState(links: state.links, loading: false, busy: true);
    try {
      final links = await operation();
      if (!ref.mounted) return;
      state = LinksState(links: links, loading: false, busy: true);
      try {
        await ref.read(linkHistoryProvider).save(links);
        if (ref.mounted) state = LinksState(links: links, loading: false);
      } on Object {
        if (ref.mounted) {
          state = LinksState(
            links: links,
            loading: false,
            error: 'Операция выполнена, но история не сохранена на устройстве.',
          );
        }
      }
    } on Object catch (error) {
      if (ref.mounted) {
        state = LinksState(
          links: state.links,
          loading: false,
          error: error is ApiException
              ? error.message
              : 'Не удалось выполнить операцию.',
        );
      }
    }
  }
}
