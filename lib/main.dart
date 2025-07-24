import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MyApp());
}

Future<void> updateHomeScreenWidget(bool hasMobileInternet) async {
  await HomeWidget.saveWidgetData(
    'circle_color',
    hasMobileInternet ? 'green' : 'red',
  );
  await HomeWidget.updateWidget(androidName: 'HomeWidgetProvider');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Просто восстановит приложение из background
      },
    );
  }

  Future<void> showStatusNotification({required bool mobileConnected}) async {
    final color = mobileConnected ? "🟢" : "🔴";
    final status = mobileConnected
        ? "Мобильный интернет есть"
        : "Нет мобильного интернета";
    // Обновляем виджет
    await updateHomeScreenWidget(mobileConnected);
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'main_channel',
          'Main Channel',
          channelDescription: 'Main notification channel',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      '$color $status',
      'Нажмите, чтобы открыть приложение',
      platformChannelSpecifics,
      payload: 'open',
    );
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _firstOpen = true;
  int _intervalMinutes = 10;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasMobile = connectivityResult.contains(ConnectivityResult.mobile);
      await NotificationService().showStatusNotification(
        mobileConnected: hasMobile,
      ); // Только при запуске
      await updateHomeScreenWidget(hasMobile);
      _startPeriodicCheck();
      if (_firstOpen) {
        _firstOpen = false;
        await Future.delayed(const Duration(milliseconds: 500));
        _minimizeApp();
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndNotify() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasMobile = connectivityResult.contains(ConnectivityResult.mobile);
    // Обновляем только виджет, уведомление не показываем
    await updateHomeScreenWidget(hasMobile);
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      Duration(minutes: _intervalMinutes),
      (_) => _checkAndNotify(),
    );
  }

  void _changeInterval(int delta) {
    setState(() {
      _intervalMinutes = (_intervalMinutes + delta).clamp(5, 60);
      _startPeriodicCheck();
    });
  }

  Future<void> _minimizeApp() async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.HOME',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    }
    // Для iOS сворачивание не поддерживается
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Сканер наличия мобильного интернета'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Периодичность проверки (мин): '),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _intervalMinutes > 5
                        ? () => _changeInterval(-5)
                        : null,
                  ),
                  Text(
                    '$_intervalMinutes',
                    style: const TextStyle(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _intervalMinutes < 60
                        ? () => _changeInterval(5)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (Platform.isAndroid)
                ElevatedButton(
                  onPressed: _minimizeApp,
                  child: const Text('Свернуть'),
                ),
              if (!Platform.isAndroid)
                const Text('Сворачивание поддерживается только на Android'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await NotificationService().cancelNotification();
                  SystemNavigator.pop();
                },
                child: const Text('Выход'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
