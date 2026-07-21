import 'package:flutter/material.dart';
import 'package:sub_get/theme.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _highPayingOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().getUserStream(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Profile Settings
              Text(
                'Account Preferences',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: AppTheme.primaryLight),
                      title: const Text('Profile Status'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.status == 'blocked'
                              ? Colors.redAccent.withOpacity(0.15)
                              : AppTheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.status.toUpperCase(),
                          style: TextStyle(
                            color: user.status == 'blocked' ? Colors.redAccent : AppTheme.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppTheme.primaryLight),
                      title: const Text('Authentication Mode'),
                      subtitle: const Text('Firebase Auth active'),
                      trailing: const Icon(Icons.verified, color: AppTheme.primaryLight, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // App Settings
              Text(
                'Notification Configuration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: AppTheme.primaryLight,
                      value: _pushNotifications,
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive alerts on task approvals'),
                      onChanged: (val) {
                        setState(() {
                          _pushNotifications = val;
                        });
                      },
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                    SwitchListTile(
                      activeColor: AppTheme.primaryLight,
                      value: _emailAlerts,
                      title: const Text('Email Summaries'),
                      subtitle: const Text('Get weekly financial cashout logs'),
                      onChanged: (val) {
                        setState(() {
                          _emailAlerts = val;
                        });
                      },
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                    SwitchListTile(
                      activeColor: AppTheme.primaryLight,
                      value: _highPayingOnly,
                      title: const Text('High-Paying Filter'),
                      subtitle: const Text('Only alert on tasks above 100 BTC'),
                      onChanged: (val) {
                        setState(() {
                          _highPayingOnly = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // System Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Social Booster App Version v1.0.0',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Running on Firebase Authentication & Firestore',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
