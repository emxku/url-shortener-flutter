import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/short_link.dart';

abstract interface class LinkHistory {
  Future<List<ShortLink>> load();
  Future<void> save(List<ShortLink> links);
}

class PreferencesLinkHistory implements LinkHistory {
  PreferencesLinkHistory(this.preferences, this.key);
  final SharedPreferencesAsync preferences;
  final String key;
  @override
  Future<List<ShortLink>> load() async {
    final raw = await preferences.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((item) => ShortLink.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(List<ShortLink> links) => preferences.setString(
    key,
    jsonEncode(links.map((link) => link.toJson()).toList()),
  );
}
