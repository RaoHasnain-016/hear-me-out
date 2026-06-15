import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase core
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase messaging
import 'screens/home_page.dart';
import 'theme/app_theme.dart';

// Background message handler (outside any class)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    // Request notification permission (especially important for iOS)
    _requestPermission();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.messageId}');
      if (message.notification != null) {
        print('Notification title: ${message.notification!.title}');
        print('Notification body: ${message.notification!.body}');
      }
    });

    // Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification caused app to open: ${message.messageId}');
      // You can add navigation or other logic here
    });

    // Get the FCM token for this device
    FirebaseMessaging.instance.getToken().then((token) {
      print('FCM Token: $token');
      // You can send this token to your backend for targeted messaging
    });
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hear Me Out',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: HomePage(),
    );
  }
}
