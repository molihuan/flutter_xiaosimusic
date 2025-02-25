import 'package:flutter/foundation.dart';

class AppModel extends ChangeNotifier {
  final Map<String, bool> _favorites = {};

  bool isFavorited(String filePath) {
    return _favorites[filePath] ?? false;
  }

  void toggleFavorite(String filePath) {
    _favorites[filePath] = !_favorites[filePath]!;
    notifyListeners();
  }
}