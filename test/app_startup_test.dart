import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_shortener/app/app_startup.dart';
import 'package:url_shortener/shared/ui/app_style.dart';

void main() {
  testWidgets(
    'Launch blocks taps, transitions and does not replay on rebuild',
    (tester) async {
      var taps = 0;
      Widget app() => MaterialApp(
        theme: AppStyle.theme,
        home: AppStartup(
          child: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Главный экран'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      expect(find.text('shortly'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.text('Главный экран'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pumpAndSettle();
      expect(find.text('shortly'), findsNothing);
      await tester.tap(find.text('Главный экран'));
      expect(taps, 1);
      await tester.pumpWidget(app());
      expect(find.text('shortly'), findsNothing);
    },
  );

  testWidgets(
    'Reduced motion finishes quickly and disposal cancels animation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const AppStartup(child: SizedBox.expand()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('shortly'), findsNothing);
      await tester.pumpWidget(
        const MaterialApp(home: AppStartup(child: SizedBox.expand())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
