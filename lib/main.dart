import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'entities/short_link/short_link.dart';
import 'features/manage_links/manage_links.dart';
import 'shared/api/api_client.dart';
import 'shared/config/api_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = ApiConfig(
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  );
  runApp(
    ProviderScope(
      overrides: [
        linkRepositoryProvider.overrideWith((ref) {
          final client = http.Client();
          ref.onDispose(client.close);
          return HttpLinkRepository(ApiClient(client, config));
        }),
        linkHistoryProvider.overrideWith(
          (ref) => PreferencesLinkHistory(
            SharedPreferencesAsync(),
            'links.v1.${config.baseUri.origin}',
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
