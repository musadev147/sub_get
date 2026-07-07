import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockDatabase(),
      builder: (context, child) {
        final db = MockDatabase();
        final user = db.currentUser;
        if (user == null) return const SizedBox.shrink();

        // Calculate work counts
        final myTasks = db.tasks.where((t) => t.workerId == user.id);
        final completedCount = myTasks.where((t) => t.status == 'completed').length;
        final pendingCount = myTasks.where((t) => t.status == 'pending').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Information Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Worker Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Completed Work',
                      '$completedCount',
                      Icons.check_circle_outline,
                      AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Pending Work',
                      '$pendingCount',
                      Icons.pending_actions,
                      AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Menu Options
              _buildMenuItem(
                context,
                title: 'Coin Wallet',
                subtitle: 'Check transactions & daily earn logs',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
              _buildMenuItem(
                context,
                title: 'Withdraw Coins',
                subtitle: 'Cash out to bKash, Nagad, Rocket, Bank',
                icon: Icons.payments_outlined,
                onTap: () => Navigator.pushNamed(context, '/withdraw'),
              ),
              if (db.isAdmin)
                _buildMenuItem(
                  context,
                  title: 'Admin Control Portal',
                  subtitle: 'Manage approvals, timers, block list',
                  icon: Icons.admin_panel_settings_outlined,
                  iconColor: AppTheme.accent,
                  onTap: () => Navigator.pushNamed(context, '/admin_portal'),
                ),
              _buildMenuItem(
                context,
                title: 'Notifications',
                subtitle: 'Updates on task completions and withdrawals',
                icon: Icons.notifications_none_outlined,
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              _buildMenuItem(
                context,
                title: 'Settings',
                subtitle: 'Configure details & configurations',
                icon: Icons.settings_outlined,
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              const SizedBox(height: 12),
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: AppTheme.cardBg,
                        title: const Text('Log Out'),
                        content: const Text('Are you sure you want to logout from your account?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await db.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = AppTheme.primaryLight,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor, size: 26),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}
