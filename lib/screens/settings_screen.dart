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
              // Danger Zone
              Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Permanently remove your account & all data'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: AppTheme.cardBg,
                        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
                        content: const Text(
                          'Are you sure you want to permanently delete your account and all associated data? This action is irreversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () async {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );
                              try {
                                await AuthService().deleteAccount();
                                if (context.mounted) {
                                  Navigator.pop(context); // Dismiss progress
                                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Your account and data have been successfully deleted.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context); // Dismiss progress
                                  String errorMsg = e.toString();
                                  if (errorMsg.contains('requires-recent-login')) {
                                    errorMsg = 'For security reasons, please log out, sign back in, and try deleting your account again immediately.';
                                  }
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      backgroundColor: AppTheme.cardBg,
                                      title: const Text('Authentication Required'),
                                      content: Text(errorMsg),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Delete Permanently'),
                          ),
                        ],
                      ),
                    );
                  },
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
                      'Earn Cash Home App Version v1.0.0',
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
