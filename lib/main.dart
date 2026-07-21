import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';
import 'package:sub_get/screens/splash_screen.dart';
import 'package:sub_get/screens/login_screen.dart';
import 'package:sub_get/screens/navigation_shell.dart';
import 'package:sub_get/screens/task_details_screen.dart';
import 'package:sub_get/screens/create_campaign_screen.dart';
import 'package:sub_get/screens/wallet_screen.dart';
import 'package:sub_get/screens/withdraw_screen.dart';
import 'package:sub_get/screens/settings_screen.dart';
import 'package:sub_get/screens/notifications_screen.dart';
import 'package:sub_get/screens/signup_screen.dart';
import 'package:sub_get/screens/forgot_password_screen.dart';
import 'package:sub_get/screens/support_screen.dart';
import 'package:sub_get/screens/email_verification_screen.dart';
import 'package:sub_get/services/push_notification_service.dart';

import 'package:sub_get/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize Push Notifications
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  // Initialize local DB and preferences state notifier
  final db = MockDatabase();
  await db.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Booster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const NavigationShell(),
        '/task_details': (context) => const TaskDetailsScreen(),
        '/create_campaign': (context) => const CreateCampaignScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/withdraw': (context) => const WithdrawScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/support': (context) => const SupportScreen(),
        '/verify_email': (context) => const EmailVerificationScreen(),
      },
    );
  }
}
