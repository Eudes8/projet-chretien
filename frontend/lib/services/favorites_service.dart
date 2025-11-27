import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FavoritesService extends ChangeNotifier {
  static const String _favoritesKey = 'user_favorites';
  Set<int> _favoriteIds = {};
  
  Set<int> get favoriteIds => _favoriteIds;
  
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    _favoriteIds = favoritesJson.map((id) => int.parse(id)).toSet();
    notifyListeners();
  }
  
  Future<void> toggleFavorite(int publicationId) async {
    if (_favoriteIds.contains(publicationId)) {
      _favoriteIds.remove(publicationId);
    } else {
      _favoriteIds.add(publicationId);
    }
    
    await _saveFavorites();
    notifyListeners();
  }
  
  bool isFavorite(int publicationId) {
    return _favoriteIds.contains(publicationId);
  }
  
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = _favoriteIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }
  
  int get favoritesCount => _favoriteIds.length;
}
