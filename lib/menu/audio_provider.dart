import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import '../song_page.dart';
import 'NotificationHelper.dart';
import 'dart:math';

class AudioProvider with ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  String? currentFilePath;
  bool isPlaying = false;
  List<String> audioFiles = []; // 存储音乐列表

  AudioProvider() {
    // 监听播放器状态变化，自动更新 UI 和通知栏
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready) {
        isPlaying = state.playing;
        updateNotification();
        notifyListeners();
      }
    });

    // 监听播放结束事件
    audioPlayer.positionStream.listen((position) {
      if (position >= (audioPlayer.duration ?? Duration.zero)) {
        isPlaying = false;
        updateNotification();
        notifyListeners();
        audioPlayer.seek(Duration.zero);
      }
    });
  }

  // 设置音乐列表
  void setAudioFiles(List<String> files) {
    audioFiles = files;
    notifyListeners();
  }

  // 更新通知栏状态
  void updateNotification() {
    NotificationHelper.showNotification(
      id: 1,
      title: isPlaying ? '正在播放' : '暂停播放',
      body: currentFilePath?.split('/').last ?? '未知歌曲',
      payload: currentFilePath,
    );
  }

  // 播放或暂停音频
  Future<void> togglePlay(String filePath) async {
    try {
      if (filePath != currentFilePath) {
        // 如果切换歌曲，先停止当前播放
        if (isPlaying) {
          await audioPlayer.stop();
        }
        if (filePath.startsWith('assets/')) {
          await audioPlayer.setAsset(filePath);
        } else {
          await audioPlayer.setFilePath(filePath);
        }
        currentFilePath = filePath;
      }

      if (isPlaying) {
        await audioPlayer.pause();
        _showToast("停止播放");
      } else {
        await audioPlayer.play();
      }
      isPlaying = !isPlaying;
      updateNotification();
      notifyListeners();
    } catch (e) {
      // _showToast("(●'◡'●)");
      print('播放出错: $e');
    }
  }

  // 随机播放歌曲
  Future<void> playRandomSong() async {
    final random = Random();
    final randomIndex = random.nextInt(audioFiles.length);
    final randomSongPath = audioFiles[randomIndex];
    await togglePlay(randomSongPath);
  }

  // 停止播放
  Future<void> stop() async {
    await audioPlayer.stop();
    isPlaying = false;
    currentFilePath = null;
    updateNotification();
    notifyListeners();
  }

  // 获取当前播放状态
  bool get getIsPlaying => isPlaying;

  // 获取当前播放文件路径
  String? get getCurrentFilePath => currentFilePath;

  static void _showToast(String message) {
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

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}