import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent search queries for the search screen (Figma 21-3653).
class RecentSearchRepository {
  static const _key = 'recent_search_queries';
  static const _maxItems = 10;

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    return list ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    var list = await getRecentSearches();
    list = [trimmed, ...list.where((s) => s != trimmed)].take(_maxItems).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
  }

  Future<void> removeRecentSearch(String query) async {
    var list = await getRecentSearches();
    list = list.where((s) => s != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
