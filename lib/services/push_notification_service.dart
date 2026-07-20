import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sub_get/mock_database.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _saveNotificationLocally(message);
}

Future<void> _saveNotificationLocally(RemoteMessage message) async {
  final db = MockDatabase();
  await db.init(); // ensure preferences are loaded

  final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  db.addNotification(db.currentUser?.id ?? 'system', title, body);
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request Permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Configure Local Notifications for Foreground display
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
    
    await _localNotifications.initialize(settings: initSettings);

    // Subscribe to a topic to receive broadcast messages to ALL devices easily
    await _firebaseMessaging.subscribeToTopic('all');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 
      'High Importance Notifications', 
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Show heads up notification
      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              priority: Priority.high,
              importance: Importance.max,
            ),
          ),
        );
      }

      // Save to local database
      await _saveNotificationLocally(message);
    });

    // Get and print the FCM token so the user can use it for testing
    String? token = await _firebaseMessaging.getToken();
    print("====================================");
    print("FCM Registration Token for Testing: ");
    print(token);
    print("====================================");
  }
}
