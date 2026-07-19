import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/firestore_service.dart';

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
    // Helper to add dummy tasks to Firebase if empty (for testing)
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
    final user = MockDatabase().currentUser; // Using Mock for User auth context for now
    
    // First StreamBuilder for Completed Task IDs
    return StreamBuilder<List<String>>(
      stream: user != null ? _firestoreService.getCompletedTaskIds(user.id) : const Stream.empty(),
      builder: (context, completedSnapshot) {
        final completedTaskIds = completedSnapshot.data ?? [];

        // Second StreamBuilder for Active Campaigns
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

            // Dynamically get categories based on Firebase data
            final Set<String> dynamicCategories = {'All'};
            for (var c in campaigns) {
              if (c.type.contains('Facebook')) dynamicCategories.add('Facebook');
              else if (c.type.contains('YouTube')) dynamicCategories.add('YouTube');
              else if (c.type.contains('Website')) dynamicCategories.add('Websites');
              else dynamicCategories.add(c.type); // Catch-all for other types
            }

            // Filter campaigns: must not be fully completed, and not created by current user
            final activeCampaigns = campaigns.where((c) {
              if (c.completedWorkers >= c.totalWorkers) return false;
              if (c.createdBy == user?.id) return false; // Can't work on own campaigns
              
              // Filter by selected category chip
              if (_selectedFilter != 'All') {
                if (_selectedFilter == 'Facebook' && !c.type.contains('Facebook')) return false;
                else if (_selectedFilter == 'YouTube' && !c.type.contains('YouTube')) return false;
                else if (_selectedFilter == 'Websites' && !c.type.contains('Website')) return false;
                else if (!['Facebook', 'YouTube', 'Websites'].contains(_selectedFilter) && c.type != _selectedFilter) return false;
              }
              
              // Hide tasks that this user already completed successfully (Checked against Firebase now!)
              if (completedTaskIds.contains(c.id)) return false;
              
              return true;
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Available Tasks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete actions to earn instant coins',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  // Dynamic Filter Chips from Firebase
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dynamicCategories.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(filter),
                            onSelected: (val) {
                              setState(() {
                                // If user selects a filter that disappears later, it stays selected until changed
                                _selectedFilter = filter;
                              });
                            },
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryLight,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Task List
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
                                  'Check back later or change filter preferences',
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
                                    // Thumbnail/Icon
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
                                    // Task details
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
                                    // Start Button
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
              ),
            );
          },
        );
      },
    );
  }
}
