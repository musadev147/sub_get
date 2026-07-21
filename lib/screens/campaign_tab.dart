import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/firestore_service.dart';
import 'package:sub_get/services/auth_service.dart';

class CampaignTab extends StatelessWidget {
  const CampaignTab({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.secondary;
      case 'pending':
        return AppTheme.accent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().getUserStream(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        
        if (user == null) {
          return const Center(child: Text('Please log in to view campaigns.'));
        }

        return StreamBuilder<List<Campaign>>(
          stream: FirestoreService().getUserCampaigns(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final myCampaigns = snapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Campaigns',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Promote your links & check worker progress',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Button to Create
                  ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/create_campaign');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Campaign'),
                    ),
                  const SizedBox(height: 20),
                  // List of campaigns
                  Expanded(
                    child: myCampaigns.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.campaign_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                const Text(
                                  'No campaigns yet',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap the button above to boost your social page',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: myCampaigns.length,
                            itemBuilder: (context, index) {
                              final camp = myCampaigns[index];
                              final statusColor = _getStatusColor(camp.status);
                              final totalCost = camp.rewardCoin * camp.totalWorkers;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.cardGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            camp.type,
                                            style: const TextStyle(
                                              color: AppTheme.primaryLight,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                camp.status.toUpperCase(),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                FirestoreService().deleteCampaign(camp.id);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      camp.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      camp.link,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Divider(height: 24, color: AppTheme.border),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Reward/Worker', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text('${camp.rewardCoin} Coins', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Workers progress', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text('${camp.completedWorkers}/${camp.totalWorkers}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Total Budget', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text('$totalCost Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
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
