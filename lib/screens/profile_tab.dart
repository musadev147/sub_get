import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/firestore_service.dart';

import '../services/auth_service.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

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
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                          backgroundImage: user.imageBase64 != null 
                              ? MemoryImage(base64Decode(user.imageBase64!))
                              : null,
                          child: user.imageBase64 == null ? Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                          ) : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.cardBg,
                            shape: BoxShape.circle,
                          ),
                          child: InkWell(
                            onTap: () => _showEditProfileDialog(context, user),
                            child: const Icon(Icons.edit, size: 20, color: AppTheme.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showEditProfileDialog(context, user),
                          child: const Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
                        ),
                      ],
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
              StreamBuilder<List<String>>(
                stream: FirestoreService().getCompletedTaskIds(user.id),
                builder: (context, completedSnapshot) {
                  return StreamBuilder<List<Campaign>>(
                    stream: FirestoreService().getActiveCampaigns(),
                    builder: (context, campaignsSnapshot) {
                      final completedCount = completedSnapshot.data?.length ?? 0;
                      final totalActive = campaignsSnapshot.data?.length ?? 0;
                      final pendingCount = (totalActive - completedCount).clamp(0, 9999);

                      return Row(
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
                      );
                    },
                  );
                },
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
              _buildMenuItem(
                context,
                title: 'Support & Help Desk',
                subtitle: 'FAQ & ask for administrator assistance',
                icon: Icons.support_agent_outlined,
                onTap: () => Navigator.pushNamed(context, '/support'),
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
                              await AuthService().logout();
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor, size: 26),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppUser user) {
    final nameController = TextEditingController(text: user.name);
    String? newImageBase64 = user.imageBase64;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Edit Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          newImageBase64 = base64Encode(bytes);
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                      backgroundImage: newImageBase64 != null 
                          ? MemoryImage(base64Decode(newImageBase64!))
                          : null,
                      child: newImageBase64 == null
                          ? const Icon(Icons.camera_alt, color: AppTheme.primaryLight, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap image to change', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      await AuthService().updateProfile(
                        nameController.text.trim(),
                        user.phone,
                        imageBase64: newImageBase64,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
