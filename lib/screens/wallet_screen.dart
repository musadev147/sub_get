import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/services/firestore_service.dart';
import 'package:sub_get/services/auth_service.dart';
import 'package:sub_get/theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        // Calculate today's earn & total earn
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        
        final userTrans = MockDatabase().transactions.where((t) => t.userId == user.id);

        final todayEarn = userTrans
            .where((t) => t.type == 'reward' && t.createdAt.isAfter(todayStart))
            .fold(0, (sum, t) => sum + t.coin);

        final totalEarn = userTrans
            .where((t) => t.type == 'reward')
            .fold(0, (sum, t) => sum + t.coin);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Balance Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'CURRENT BALANCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on, color: AppTheme.accent, size: 36),
                        const SizedBox(width: 8),
                        Text(
                          '${user.coin}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$todayEarn',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text('Today Earned', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.white24),
                        Column(
                          children: [
                            Text(
                              '$totalEarn',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text('Total Earned', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Withdrawal History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/withdraw'),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    label: const Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService().getUserWithdrawals(user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }

                    final withdrawHistory = snapshot.data?.docs ?? [];
                    
                    // Sort locally to avoid Firebase index error
                    withdrawHistory.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTime = aData['requestedAt'] != null 
                          ? (aData['requestedAt'] as Timestamp).toDate() 
                          : DateTime.now();
                      final bTime = bData['requestedAt'] != null 
                          ? (bData['requestedAt'] as Timestamp).toDate() 
                          : DateTime.now();
                      return bTime.compareTo(aTime); // Descending order
                    });

                    if (withdrawHistory.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text('No withdrawals requested yet', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: withdrawHistory.length,
                      itemBuilder: (context, index) {
                        final doc = withdrawHistory[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        final status = data['status'] ?? 'pending';
                        final method = data['method'] ?? 'Unknown';
                        final amount = data['amount'] ?? 0;
                        final createdAt = data['requestedAt'] != null 
                            ? (data['requestedAt'] as Timestamp).toDate() 
                            : DateTime.now();
                        
                        final isApproved = status == 'approved' || status == 'paid';
                        final isPending = status == 'pending';
                        final statusColor = isApproved
                            ? AppTheme.secondary
                            : isPending
                                ? AppTheme.accent
                                : Colors.redAccent;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: statusColor.withOpacity(0.1),
                                child: Icon(
                                  isApproved
                                      ? Icons.check
                                      : isPending
                                          ? Icons.hourglass_empty
                                          : Icons.close,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payout: $method',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '-$amount BTC',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
