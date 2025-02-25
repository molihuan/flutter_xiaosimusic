import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

class MenuViewModel extends ChangeNotifier {
  List<String> audioFiles = [];
  Map<String, bool> isFavorited = {}; // 用于记录每个文件的收藏状态

  MenuViewModel() {
    _loadFavorites(); // 加载收藏状态
    _loadAudioFiles(); // 加载本地歌曲列表
    _initializeDefaultFiles(); // 初始化默认的内置音乐文件
  }

  Future<void> _initializeDefaultFiles() async {
    // 初始化默认的内置音乐文件
    final defaultFiles = [
      'assets/music/光与影的对白.flac', // 示例内置音乐文件路径
      // 可以根据需要添加更多默认文件
    ];

    // 检查是否已经加载过默认文件
    if (audioFiles.isEmpty) {
      audioFiles.addAll(defaultFiles);
      isFavorited.addAll(defaultFiles.map((file) => MapEntry(file, false)) as Map<String, bool>);
      await _saveAudioFiles(); // 保存到本地文件
    }
  }

  Future<void> _loadFavorites() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/收藏.txt');
    if (await file.exists()) {
      final contents = await file.readAsString();
      final favorites = contents.split(',');
      for (var filePath in favorites) {
        if (filePath.isNotEmpty) {
          isFavorited[filePath] = true;
        }
      }
    }
    notifyListeners();
  }

  Future<void> _loadAudioFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/歌曲列表.txt');
    if (await file.exists()) {
      final contents = await file.readAsString();
      audioFiles = contents.split(',');
    }
    notifyListeners();
  }

  Future<String?> _showFilePathInputDialog(BuildContext context) async {
    String filePath = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("添加音频文件"),
          content: TextField(
            onChanged: (value) {
              filePath = value;
            },
            decoration: InputDecoration(hintText: "请输入音频文件路径"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, filePath),
              child: Text("确定"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("取消"),
            ),
          ],
        );
      },
    );
  }

  Future<void> addSongFromDevice(BuildContext context) async {
    final filePath = await _showFilePathInputDialog(context);
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("文件不存在: $filePath")),
      );
      return;
    }

    audioFiles.add(filePath);
    isFavorited[filePath] = false;
    await _saveAudioFiles(); // 保存歌曲列表
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("添加成功: $filePath")),
    );
  }

  Future<void> _saveAudioFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/歌曲列表.txt');
    await file.writeAsString(audioFiles.join(',')); // 保存歌曲列表
  }

  void toggleFavorite(String filePath) {
    if (!isFavorited.containsKey(filePath)) {
      isFavorited[filePath] = false;
    }
    isFavorited[filePath] = !(isFavorited[filePath] ?? false);
    _saveFavorites(); // 保存收藏状态
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/收藏.txt');
    final favorites = isFavorited.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
    await file.writeAsString(favorites.join(',')); // 保存收藏状态
  }

  List<String> getAudioFiles() {
    return audioFiles;
  }

  List<String> getFavorites() {
    return audioFiles.where((file) => isFavorited[file] ?? false).toList();
  }

  bool getIsFavorited(String filePath) {
    return isFavorited[filePath] ?? false;
  }

  // 新增删除歌曲的方法
  Future<void> deleteSong(String filePath) async {
    if (filePath.startsWith('assets/music/光与影的对白.flac')) {
      // 如果是内置歌曲，不进行删除操作
      _showToast("内置歌曲不能删除喵");
      return;
    }
    // 从 audioFiles 列表中移除歌曲
    audioFiles.remove(filePath);
    // 从收藏状态中移除该歌曲的记录
    isFavorited.remove(filePath);
    // 更新本地歌曲列表文件
    await _saveAudioFiles();
    // 更新本地收藏文件
    await _saveFavorites();
    notifyListeners();
  }
}
void _showToast(String message) {
Fluttertoast.showToast(
msg: message,
toastLength: Toast.LENGTH_SHORT,
gravity: ToastGravity.BOTTOM,
timeInSecForIosWeb: 1,
backgroundColor: Colors.black87,
textColor: Colors.white,
fontSize: 16.0,
);
}