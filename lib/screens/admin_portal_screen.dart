import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  final _minWithdrawController = TextEditingController();
  final _globalTimerController = TextEditingController();
  bool _isConfigLoading = false;

  @override
  void initState() {
    super.initState();
    final db = MockDatabase();
    _minWithdrawController.text = db.minWithdrawCoins.toString();
    _globalTimerController.text = db.adminGlobalTimer.toString();
  }

  @override
  void dispose() {
    _minWithdrawController.dispose();
    _globalTimerController.dispose();
    super.dispose();
  }

  void _saveConfigs() async {
    setState(() {
      _isConfigLoading = true;
    });

    final minW = int.tryParse(_minWithdrawController.text.trim()) ?? 1000;
    final timer = int.tryParse(_globalTimerController.text.trim()) ?? 20;

    await MockDatabase().adminSetGlobalSettings(minW, timer);

    setState(() {
      _isConfigLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Global Admin Settings Saved Successfully!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Portal'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.campaign), text: 'Campaigns'),
              Tab(icon: Icon(Icons.payments), text: 'Withdraws'),
              Tab(icon: Icon(Icons.settings), text: 'Config'),
            ],
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: ListenableBuilder(
          listenable: MockDatabase(),
          builder: (context, _) {
            final db = MockDatabase();
            
            // Pending campaigns
            final pendingCamps = db.campaigns.where((c) => c.status == 'pending').toList();
            
            // Pending withdrawals
            final pendingWithdraws = db.transactions
                .where((t) => t.type == 'withdraw_request' && t.status == 'pending')
                .toList();

            return TabBarView(
              children: [
                // Tab 1: Campaigns Approval
                _buildCampaignsTab(context, pendingCamps, db),

                // Tab 2: Withdrawals Approval
                _buildWithdrawalsTab(context, pendingWithdraws, db),

                // Tab 3: Global System Settings
                _buildSettingsTab(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCampaignsTab(BuildContext context, List<Campaign> list, MockDatabase db) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppTheme.secondary),
            SizedBox(height: 16),
            Text('No pending campaigns for review', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final camp = list[index];
        final budget = camp.rewardCoin * camp.totalWorkers;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
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
                      style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    'Creator ID: ${camp.createdBy}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(camp.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(camp.link, style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
              const Divider(height: 24, color: AppTheme.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reward: ${camp.rewardCoin} c', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                  Text('Workers: ${camp.totalWorkers}'),
                  Text('Budget: $budget c', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => db.adminRejectCampaign(camp.id),
                      child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => db.adminApproveCampaign(camp.id),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWithdrawalsTab(BuildContext context, List<WalletTransaction> list, MockDatabase db) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, size: 64, color: AppTheme.secondary),
            SizedBox(height: 16),
            Text('No pending withdrawal requests', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Method: ${tx.withdrawMethod}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accent),
                  ),
                  Text(
                    'Coins: ${tx.coin}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Destination Account: ${tx.withdrawAccount}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Requester User ID: ${tx.userId}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const Divider(height: 24, color: AppTheme.border),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => db.adminRejectWithdraw(tx.id),
                      child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => db.adminApproveWithdraw(tx.id),
                      child: const Text('Approve payout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Global System Thresholds',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _minWithdrawController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minimum Coin Withdrawal limit',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _globalTimerController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Default Stay Timer (Seconds)',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isConfigLoading ? null : _saveConfigs,
            child: _isConfigLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Parameters'),
          ),
        ],
      ),
    );
  }
}
