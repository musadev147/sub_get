import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark notifications as read when opening this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MockDatabase().markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockDatabase(),
      builder: (context, _) {
        final db = MockDatabase();
        final user = db.currentUser;
        if (user == null) return const SizedBox.shrink();

        final userNotifications = db.notifications
            .where((n) => n.userId == user.id)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
          ),
          body: userNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We will notify you about approvals and updates.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: userNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = userNotifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: notif.isRead ? AppTheme.cardBg : const Color(0xFF1E293B).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: notif.isRead ? AppTheme.border : AppTheme.primaryLight.withOpacity(0.3),
                          width: notif.isRead ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notif.title.contains('Approved') || notif.title.contains('Success')
                                  ? Icons.check_circle_outline
                                  : notif.title.contains('Rejected')
                                      ? Icons.cancel_outlined
                                      : Icons.info_outline,
                              color: notif.title.contains('Approved') || notif.title.contains('Success')
                                  ? AppTheme.secondary
                                  : notif.title.contains('Rejected')
                                      ? Colors.redAccent
                                      : AppTheme.primaryLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif.body,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(notif.createdAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
