import 'package:material_ui/material_ui.dart';

import '../pages/shortener/shortener.dart';
import '../shared/ui/app_style.dart';
import 'app_startup.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'URL Shortener',
    debugShowCheckedModeBanner: false,
    theme: AppStyle.theme,
    home: const AppStartup(child: ShortenerPage()),
  );
}
