import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/api/firebase_api.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("onMessageOpenedApp: $message");
    // 푸시 알림을 처리하는 로직을 추가하세요.
    Navigator.of(navigatorKey.currentState!.context).pushNamed(
      '/push-page',
      arguments: {"message", json.encode(message.data)},
    );
  });

  // If App is closed or terminated
  FirebaseMessaging.instance.getInitialMessage().then((
          (RemoteMessage? message) {
        if (message != null) {
          Navigator.pushNamed(
            navigatorKey.currentState!.context,
            '/push-page',
            arguments: {"message", json.encode(message.data)},
          );
        }
      }
  ));

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessageBackgroundHandler
  );

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessageBackgroundHandler(RemoteMessage message) async {
  // FlutterAppBadger.updateBadgeCount(message.notification?.android?.count ?? 0);
  await Firebase.initializeApp();
  print("_firebaseMessagingBackgroundHandler: $message");
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
      ),
      home: const MyHomePage(),
      routes: {
        '/push-page': ((context) => const HomePage()),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Emptypage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Page'),
      ),
      body: const Center(
        child: Text('Welcome to Push Notification Page!'),
      ),
    );
  }
}

Future<bool> _doesDrawableFileExist(String fileName) async {
  try {
    // Check if the file exists in the assets (res/drawable) directory
    ByteData data = await rootBundle.load('assets/$fileName.png');
    return data.lengthInBytes != 0;
  } catch (e) {
    print('Error: $e');
    // Handle any errors that may occur during file existence check
    return false;
  }
}

class Emptypage extends StatelessWidget {
  const Emptypage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseApi().initNotifications();
    // //For Foreground State
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_notification_channel_id',
        'default_notification_channel_id',
        description: '테스트 알림입니다.',
        importance: Importance.max
    );
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    //foreground 푸시 알림 핸들링
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      print('Got a message whilst in the foreground!');
      print('Message data: ${message.notification?.title}');
      print('Message MetaData: ${message.data}');
      print('icon: ${message.notification?.android?.smallIcon}');

      String? iconName = message.notification?.android?.smallIcon;
      print('iconName11111111111111: $iconName');
      print(await _doesDrawableFileExist(iconName!));

      // Check if the icon file exists in the drawable directory
      if (await _doesDrawableFileExist(iconName)) {
      // Use the received icon file
        iconName = message.notification?.android?.smallIcon;
      } else {
        // Use the default icon file
        iconName = 'ic_notification';
      }

       var notificationCount = message.notification?.android?.count;

      print("count: ${message.notification?.android?.count}");

      if (message.notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification?.title,
            notification?.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: iconName,
                number: notificationCount,
              ),
            )
        );

        print('Message also contained a notification: ${message.notification}');

        // 수정된 부분: 알림 수신 후 '/push-page'로 라우팅
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(navigatorKey.currentState!.context, '/push-page');
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empty Page'),
      ),
      body: const Center(
        child: Text('This is an empty page!'),
      ),
    );
  }
}