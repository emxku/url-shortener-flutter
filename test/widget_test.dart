import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_shortener/app/app.dart';
import 'package:url_shortener/entities/short_link/api/link_history.dart';
import 'package:url_shortener/entities/short_link/api/link_repository.dart';
import 'package:url_shortener/entities/short_link/model/short_link.dart';
import 'package:url_shortener/features/manage_links/model/link_controller.dart';
import 'package:url_shortener/shared/api/api_client.dart';

class MemoryHistory implements LinkHistory {
  List<ShortLink> links = [];
  bool fail = false;
  @override
  Future<List<ShortLink>> load() async => links;
  @override
  Future<void> save(List<ShortLink> value) async {
    if (fail) throw Exception('disk');
    links = value;
  }
}

class FakeRepository implements LinkRepository {
  int creates = 0;
  bool failDelete = false;
  @override
  Future<ShortLink> create(String url) async {
    creates++;
    return ShortLink(
      originalUrl: url,
      shortUrl: 'https://short.test/abc',
      expiresAt: null,
      clickCount: 0,
    );
  }

  @override
  Future<void> delete(String code) async {
    if (failDelete) throw const ApiException('Ошибка сервера');
  }

  @override
  Future<Uint8List> qr(String code) async => Uint8List(0);
}

void main() {
  testWidgets('Validation, create and confirmed deletion', (tester) async {
    final repository = FakeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkRepositoryProvider.overrideWithValue(repository),
          linkHistoryProvider.overrideWithValue(MemoryHistory()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сократить ссылку'));
    await tester.pumpAndSettle();
    expect(repository.creates, 0);
    await tester.enterText(
      find.byType(TextFormField),
      'https://example.com/Path',
    );
    await tester.tap(find.text('Сократить ссылку'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('https://short.test/abc'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('https://short.test/abc'), findsOneWidget);
    await tester.ensureVisible(find.text('Удалить'));
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('https://short.test/abc'), findsNothing);
  });
  testWidgets('Narrow screen supports large text and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkRepositoryProvider.overrideWithValue(FakeRepository()),
          linkHistoryProvider.overrideWithValue(MemoryHistory()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Начнём с первой ссылки?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test(
    'Failed deletion retains link; storage failure retains created result',
    () async {
      final repository = FakeRepository();
      final history = MemoryHistory()..fail = true;
      final container = ProviderContainer(
        overrides: [
          linkRepositoryProvider.overrideWithValue(repository),
          linkHistoryProvider.overrideWithValue(history),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(linkControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await controller.create('https://example.com');
      var state = container.read(linkControllerProvider);
      expect(state.links, hasLength(1));
      expect(state.error, contains('не сохранена'));
      repository.failDelete = true;
      await controller.delete(state.links.first);
      state = container.read(linkControllerProvider);
      expect(state.links, hasLength(1));
      expect(state.busy, false);
      expect(state.error, 'Ошибка сервера');
    },
  );
}
