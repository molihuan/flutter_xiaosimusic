import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'audio_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const String NOTIFICATION_CHANNEL_ID = 'your_channel_id';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static BuildContext? _context;

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 检查并请求通知权限
    if (await Permission.notification.request().isGranted) {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          if (_context != null) {
            // 获取 AudioProvider 实例
            final audioProvider = Provider.of<AudioProvider>(
                _context!, listen: false);
            switch (response.actionId) {
              case 'play_pause_action':
                try {
                  audioProvider.togglePlay(audioProvider.getCurrentFilePath ?? '');
                } catch (e) {
                  print('Error toggling play/pause: $e');
                }
                break;
              case 'skip_previous_action':
                print('Skip Previous'); // 暂未实现上一曲逻辑
                break;
              case 'skip_next_action':
                print('Skip Next'); // 暂未实现下一曲逻辑
                break;
            }
          } else {
            print('Error: BuildContext is null in onDidReceiveNotificationResponse');
          }
        },
        onDidReceiveBackgroundNotificationResponse: backgroundNotificationResponse,
      );
    } else {
      print('Notification permission not granted');
    }
  }

  @pragma('vm:entry-point')
  static void backgroundNotificationResponse(NotificationResponse response) {
    print('Background notification action clicked: ${response.actionId}');
    // 在这里处理背景通知响应
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      NOTIFICATION_CHANNEL_ID, // 通知通道ID
      '显示音乐喵', // 通知通道名称
      channelDescription: '通知音乐',
      // 通知通道描述
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('skip_previous_action', '上一曲'),
        AndroidNotificationAction('play_pause_action', '播放/暂停'),
        AndroidNotificationAction('skip_next_action', '下一曲'),
      ],
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}