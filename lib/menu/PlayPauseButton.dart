import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_provider.dart'; // 确保导入 AudioProvider

class PlayPauseButton extends StatelessWidget {
  final String filePath;

  const PlayPauseButton({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: true);

    return IconButton(
      icon: Icon(
        audioProvider.getIsPlaying && audioProvider.getCurrentFilePath == filePath
            ? Icons.pause
            : Icons.play_arrow,
      ),
      onPressed: () {
        // 调用 AudioProvider 的 togglePlay 方法来控制播放
        audioProvider.togglePlay(filePath);
      },
    );
  }
}