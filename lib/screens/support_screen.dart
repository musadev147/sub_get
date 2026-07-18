import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Payment';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I earn coins in SubGet?',
      'answer': 'You can earn coins by navigating to the "Work" tab, choosing an active task, and following its instructions exactly. Typically, this involves visiting links, liking posts, or subscribing, and staying on the target page for the requested duration. Once completed, returns to the app to verify and receive coins instantly.',
    },
    {
      'question': 'What is the minimum withdrawal limit?',
      'answer': 'The minimum withdrawal limit is configured by the administration. You can view the current minimum limit by visiting the "Coin Wallet" and tapping "Withdraw". Withdrawals are processed through methods like bKash and Nagad.',
    },
    {
      'question': 'Why did my task verification fail?',
      'answer': 'Task verification can fail if you did not spend the minimum stay duration on the destination link, or if you closed the task early. Please read the campaign instructions carefully and keep the target page open until the timer completes.',
    },
    {
      'question': 'How can I promote my own campaigns?',
      'answer': 'You can navigate to the "Campaign" tab and tap "Create Campaign". You will need to specify the task title, link, type, stay timer, instructions, and target worker count. Make sure your coin wallet has enough balance to cover the total campaign budget.',
    },
    {
      'question': 'How long does withdrawal processing take?',
      'answer': 'Withdrawals are typically reviewed and approved by administrators within 12 to 24 hours of submission. Once approved, the payout is processed to your provided account number.',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showCreateTicketBottomSheet(BuildContext context, MockDatabase db) {
    _subjectController.clear();
    _messageController.clear();
    _selectedCategory = 'Payment';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Open Support Ticket',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          dropdownColor: AppTheme.cardBg,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: ['Payment', 'Task Issue', 'Campaign', 'Other']
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            prefixIcon: Icon(Icons.subtitles_outlined),
                            hintText: 'Brief summary of the issue',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a subject';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Detailed Message',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Icon(Icons.message_outlined),
                            ),
                            hintText: 'Describe your issue in detail...',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your message';
                            }
                            if (value.trim().length < 10) {
                              return 'Message should be at least 10 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              await db.createSupportTicket(
                                _selectedCategory,
                                _subjectController.text.trim(),
                                _messageController.text.trim(),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Support Ticket submitted successfully!'),
                                    backgroundColor: AppTheme.secondary,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Submit Ticket'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Support & Help Desk'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.help_outline), text: 'FAQs & Channels'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'My Tickets'),
            ],
            indicatorColor: AppTheme.primaryLight,
            labelColor: AppTheme.primaryLight,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: ListenableBuilder(
          listenable: MockDatabase(),
          builder: (context, _) {
            final db = MockDatabase();
            final user = db.currentUser;
            if (user == null) return const SizedBox.shrink();

            // Filter tickets for current user
            final userTickets = db.tickets.where((t) => t.userId == user.id).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return TabBarView(
              children: [
                // Tab 1: FAQ and Direct Channels
                _buildFaqAndChannelsTab(),

                // Tab 2: User Support Tickets
                _buildTicketsTab(userTickets, db),
              ],
            );
          },
        ),
        floatingActionButton: ListenableBuilder(
          listenable: MockDatabase(),
          builder: (context, _) {
            final db = MockDatabase();
            return FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _showCreateTicketBottomSheet(context, db),
              icon: const Icon(Icons.add),
              label: const Text('Create Ticket'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFaqAndChannelsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        const Text(
          'Need Help? We got you covered!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Read our FAQs or reach out directly via support channels.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Direct Channels Header
        const Text(
          'Direct Contact Channels',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
        ),
        const SizedBox(height: 12),

        // Channel Cards Row
        Row(
          children: [
            Expanded(
              child: _buildChannelCard(
                icon: Icons.chat_bubble_outline,
                title: 'Telegram Support',
                value: '@SubGetSupport',
                color: Colors.blueAccent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Telegram Support: @SubGetSupport')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChannelCard(
                icon: Icons.phone_android_outlined,
                title: 'WhatsApp Chat',
                value: '+880 1700-000000',
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening WhatsApp Chat: +8801700000000')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildChannelCard(
          icon: Icons.email_outlined,
          title: 'Official Support Email',
          value: 'support@subget.com',
          color: AppTheme.accent,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Drafting Email to support@subget.com')),
            );
          },
        ),
        const SizedBox(height: 28),

        // FAQs Header
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
        ),
        const SizedBox(height: 12),

        // FAQ List
        ..._faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: ExpansionTile(
                iconColor: AppTheme.primaryLight,
                collapsedIconColor: AppTheme.textSecondary,
                title: Text(
                  faq['question']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                    ),
                  )
                ],
              ),
            )),
        const SizedBox(height: 80), // extra padding for FAB
      ],
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsTab(List<SupportTicket> tickets, MockDatabase db) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: AppTheme.primaryLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No support tickets found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Create Ticket" to file a support request.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length + 1,
      itemBuilder: (context, index) {
        if (index == tickets.length) {
          return const SizedBox(height: 80); // padding for FAB
        }
        final ticket = tickets[index];
        final isResolved = ticket.status == 'resolved';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? AppTheme.secondary.withOpacity(0.15)
                        : Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: TextStyle(
                      color: isResolved ? AppTheme.secondary : Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.category,
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                    'Created: ${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year} ${ticket.createdAt.hour}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
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
                      'Your Message:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.message,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    if (ticket.reply != null) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppTheme.border),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Support Reply:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                          ),
                          if (ticket.repliedAt != null)
                            Text(
                              '${ticket.repliedAt!.day}/${ticket.repliedAt!.month} ${ticket.repliedAt!.hour}:${ticket.repliedAt!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
                        ),
                        child: Text(
                          ticket.reply!,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
