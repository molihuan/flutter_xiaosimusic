import 'package:flutter/foundation.dart';

class AppModel extends ChangeNotifier {
  final Map<String, bool> _favorites = {}; // 用于存储收藏状态

  // 检查文件是否被收藏
  bool isFavorited(String filePath) {
    return _favorites[filePath] ?? false;
  }

  // 切换收藏状态
  void toggleFavorite(String filePath) {
    _favorites[filePath] = !_favorites[filePath]!;
    notifyListeners(); // 通知监听者状态已更新
  }
}
