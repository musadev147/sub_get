import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/firestore_service.dart';
import 'package:sub_get/services/auth_service.dart';

class CategoryItem {
  final String name;
  final String dbType;
  final IconData icon;
  final Color color;

  CategoryItem(this.name, this.dbType, this.icon, this.color);
}

final List<CategoryItem> staticCategories = [
  CategoryItem('Facebook Work', 'Facebook', Icons.facebook, const Color(0xFF1877F2)),
  CategoryItem('Instagram Work', 'Instagram', Icons.camera_alt, const Color(0xFFE1306C)),
  CategoryItem('TikTok Work', 'TikTok', Icons.music_note, Colors.black),
  CategoryItem('Website Work', 'Website', Icons.language, Colors.blueGrey),
  CategoryItem('YouTube Work', 'YouTube', Icons.play_circle_fill, const Color(0xFFFF0000)),
  CategoryItem('Admin Work', 'Admin', Icons.admin_panel_settings, Colors.blue),
  CategoryItem('Apps Work', 'Apps', Icons.apps, Colors.green),
  CategoryItem('Google Work', 'Google', Icons.search, Colors.blueAccent),
  CategoryItem('Telegram Work', 'Telegram', Icons.telegram, const Color(0xFF0088cc)),
  CategoryItem('Product Review', 'Review', Icons.rate_review, Colors.orange),
  CategoryItem('YouTube Watch', 'Watchtime', Icons.access_time, Colors.redAccent),
  CategoryItem('Help and Earn', 'Help', Icons.help, Colors.teal),
  CategoryItem('Sell', 'Sell', Icons.sell, Colors.red),
];

class WorkTab extends StatefulWidget {
  const WorkTab({super.key});

  @override
  State<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends State<WorkTab> {
  String _selectedFilter = 'All';
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _firestoreService.seedDummyCampaignsIfEmpty();
  }

  IconData _getIconForType(String type) {
    if (type.contains('Facebook')) return Icons.facebook;
    if (type.contains('YouTube')) return Icons.play_circle_fill;
    return Icons.language;
  }

  Color _getColorForType(String type) {
    if (type.contains('Facebook')) return const Color(0xFF1877F2);
    if (type.contains('YouTube')) return const Color(0xFFFF0000);
    return AppTheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().getUserStream(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) return const Center(child: CircularProgressIndicator());

        return StreamBuilder<List<String>>(
          stream: _firestoreService.getCompletedTaskIds(user.id),
          builder: (context, completedSnapshot) {
            final completedTaskIds = completedSnapshot.data ?? [];

            return StreamBuilder<List<Campaign>>(
              stream: _firestoreService.getActiveCampaigns(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final campaigns = snapshot.data ?? [];

                // Calculate available counts per static category type
                final Map<String, int> categoryCounts = {};
                for (var cat in staticCategories) {
                  categoryCounts[cat.dbType] = 0;
                }

                for (var c in campaigns) {
                  if (c.completedWorkers >= c.totalWorkers) continue;
                  if (c.createdBy == user.id) continue;
                  if (completedTaskIds.contains(c.id)) continue;
                  
                  bool matched = false;
                  for (var cat in staticCategories) {
                    if (c.type.contains(cat.dbType)) {
                      categoryCounts[cat.dbType] = (categoryCounts[cat.dbType] ?? 0) + 1;
                      matched = true;
                      break;
                    }
                  }
                  if (!matched) {
                    // fallback or generic category if needed
                  }
                }

                final activeCampaigns = campaigns.where((c) {
                  if (c.completedWorkers >= c.totalWorkers) return false;
                  if (c.createdBy == user.id) return false;
                  if (completedTaskIds.contains(c.id)) return false;
                  
                  if (_selectedFilter != 'All') {
                    if (!c.type.contains(_selectedFilter)) return false;
                  }
                  
                  return true;
                }).toList();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _selectedFilter == 'All' 
                    ? _buildCategoriesGrid(categoryCounts)
                    : _buildTaskList(activeCampaigns),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesGrid(Map<String, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6B48FF), // Purple banner
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_open, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Created Works',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View and manage your submitted works',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Currently dummy, could navigate to campaigns tab if possible
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B48FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Select a Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the category for your work',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: staticCategories.length,
            itemBuilder: (context, index) {
              final cat = staticCategories[index];
              final count = counts[cat.dbType] ?? 0;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = cat.dbType;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count available',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<Campaign> activeCampaigns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedFilter = 'All';
                });
              },
            ),
            Text(
              '$_selectedFilter Works',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: activeCampaigns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No tasks available!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later',
                        style: TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: activeCampaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = activeCampaigns[index];
                    final color = _getColorForType(campaign.type);
                    final icon = _getIconForType(campaign.type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                            ),
                            child: Icon(icon, color: color, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    campaign.type,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  campaign.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.monetization_on, color: AppTheme.accent, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${campaign.rewardCoin} Coins',
                                          style: const TextStyle(
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer, color: AppTheme.textSecondary, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${campaign.stayTime}s required',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/task_details',
                                arguments: campaign,
                              );
                            },
                            child: const Text('Start'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

