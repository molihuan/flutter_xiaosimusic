import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xiaosimusic/song_page.dart';
import 'package:xiaosimusic/app_model.dart'; // 确保导入 AppModel
import 'package:xiaosimusic/menu/menu_vm.dart'; // 确保导入 MenuViewModel
import 'package:xiaosimusic/menu/audio_provider.dart'; // 确保导入 AudioProvider
import 'package:xiaosimusic/menu/NotificationHelper.dart'; // 导入通知服务

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppModel()), // 管理 AppModel
        ChangeNotifierProvider(create: (_) => MenuViewModel()), // 管理 MenuViewModel
        ChangeNotifierProvider(create: (_) => AudioProvider()), // 管理 AudioProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SongPage(),
    );
  }
}