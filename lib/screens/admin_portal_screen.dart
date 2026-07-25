import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/firestore_service.dart';
import 'package:sub_get/services/auth_service.dart';

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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Portal'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.campaign), text: 'Campaigns'),
              Tab(icon: Icon(Icons.payments), text: 'Withdraws'),
              Tab(icon: Icon(Icons.settings), text: 'Config'),
              Tab(icon: Icon(Icons.support_agent), text: 'Support'),
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

                // Tab 4: Support Tickets
                StreamBuilder<List<SupportTicket>>(
                  stream: FirestoreService().getAllSupportTickets(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final allTickets = snapshot.data ?? [];
                    return _buildSupportTab(context, allTickets);
                  },
                ),
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
                  FutureBuilder<AppUser?>(
                    future: AuthService().getUserById(camp.createdBy),
                    builder: (context, snapshot) {
                      String emailText = 'Loading...';
                      String actualEmail = 'Unknown';
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        actualEmail = snapshot.data!.email;
                        emailText = 'By: $actualEmail';
                      } else if (snapshot.hasError || snapshot.connectionState == ConnectionState.done) {
                        emailText = 'ID: ${camp.createdBy}';
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminUserCampaignsScreen(
                                userId: camp.createdBy,
                                userEmail: actualEmail,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            emailText,
                            style: const TextStyle(
                              color: AppTheme.accent, 
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.accent,
                            ),
                          ),
                        ),
                      );
                    },
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

  Widget _buildSupportTab(BuildContext context, List<SupportTicket> allTickets) {
    final pending = allTickets.where((t) => t.status == 'pending').toList();
    final resolved = allTickets.where((t) => t.status == 'resolved').toList();

    if (pending.isEmpty && resolved.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_chat_read_outlined, size: 64, color: AppTheme.secondary),
            SizedBox(height: 16),
            Text('All clear! No support tickets.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          const Text(
            'Pending Tickets',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber),
          ),
          const SizedBox(height: 12),
          ...pending.map((t) => _buildTicketAdminCard(context, t)),
          const SizedBox(height: 24),
        ],
        if (resolved.isNotEmpty) ...[
          const Text(
            'Resolved Tickets',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondary),
          ),
          const SizedBox(height: 12),
          ...resolved.map((t) => _buildTicketAdminCard(context, t)),
        ],
      ],
    );
  }

  Widget _buildTicketAdminCard(BuildContext context, SupportTicket ticket) {
    final isPending = ticket.status == 'pending';
    final replyController = TextEditingController();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPending ? Colors.amber.withOpacity(0.15) : AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ticket.status.toUpperCase(),
                style: TextStyle(
                  color: isPending ? Colors.amber : AppTheme.secondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${ticket.createdAt.day}/${ticket.createdAt.month} ${ticket.createdAt.hour}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'By: ${ticket.userName} (${ticket.userEmail})',
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 12),
                const Text(
                  'Message Detail:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(ticket.message, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                if (ticket.reply != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Reply:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.secondary),
                  ),
                  const SizedBox(height: 4),
                  Text(ticket.reply!, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.cardBg,
                            title: const Text('Delete Ticket'),
                            content: const Text('Are you sure you want to delete this ticket?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () async {
                                  await FirestoreService().adminDeleteTicket(ticket.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('Reply', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.cardBg,
                              title: Text('Reply to: ${ticket.subject}'),
                              content: TextFormField(
                                controller: replyController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Type your reply here...',
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    if (replyController.text.trim().isNotEmpty) {
                                      FirestoreService().adminReplyTicket(ticket.id, replyController.text.trim());
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Reply sent successfully!'),
                                          backgroundColor: AppTheme.secondary,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Send Reply', style: TextStyle(color: AppTheme.secondary)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ]
    ),
      )
    );
    }
}

class AdminUserCampaignsScreen extends StatelessWidget {
  final String userId;
  final String userEmail;

  const AdminUserCampaignsScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campaigns: $userEmail'),
      ),
      body: StreamBuilder<List<Campaign>>(
        stream: FirestoreService().getUserCampaigns(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final campaigns = snapshot.data ?? [];
          if (campaigns.isEmpty) {
            return const Center(child: Text('No campaigns found for this user.', style: TextStyle(color: AppTheme.textSecondary)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final camp = campaigns[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(camp.type, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
                        Text('Status: ${camp.status.toUpperCase()}', style: TextStyle(
                          color: camp.status == 'active' ? Colors.green : (camp.status == 'pending' ? Colors.amber : Colors.red),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(camp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Reward: ${camp.rewardCoin} Coins | Stay: ${camp.stayTime}s', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
