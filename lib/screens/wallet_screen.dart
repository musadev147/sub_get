import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockDatabase(),
      builder: (context, child) {
        final db = MockDatabase();
        final user = db.currentUser;
        if (user == null) return const SizedBox.shrink();

        // Calculate today's earn & total earn
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        
        final userTrans = db.transactions.where((t) => t.userId == user.id);

        final todayEarn = userTrans
            .where((t) => t.type == 'reward' && t.createdAt.isAfter(todayStart))
            .fold(0, (sum, t) => sum + t.coin);

        final totalEarn = userTrans
            .where((t) => t.type == 'reward')
            .fold(0, (sum, t) => sum + t.coin);

        // Filter withdraw records
        final withdrawHistory = userTrans
            .where((t) => t.type.startsWith('withdraw'))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Wallet'),
          ),
          body: Padding(
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
                // Quick cashout banner
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/withdraw');
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Request Withdraw'),
                ),
                const SizedBox(height: 24),
                // Withdraw History Header
                Text(
                  'Withdrawal History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: withdrawHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text('No withdrawals requested yet', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: withdrawHistory.length,
                          itemBuilder: (context, index) {
                            final tx = withdrawHistory[index];
                            final isApproved = tx.status == 'approved';
                            final isPending = tx.status == 'pending';
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
                                          'Payout: ${tx.withdrawMethod}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '-${tx.coin} Coins',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tx.status.toUpperCase(),
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
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
