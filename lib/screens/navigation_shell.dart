import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/theme.dart';
import 'package:sub_get/screens/work_tab.dart';
import 'package:sub_get/screens/campaign_tab.dart';
import 'package:sub_get/screens/profile_tab.dart';
import 'package:sub_get/screens/wallet_screen.dart';
import 'package:sub_get/services/auth_service.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    WorkTab(),
    CampaignTab(),
    WalletScreen(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;

        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not Authenticated or User Data Missing'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: const Text('Log Out & Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListenableBuilder(
          listenable: MockDatabase(),
          builder: (context, child) {
            final db = MockDatabase();

        // Count unread notifications
        final unreadCount = db.notifications
            .where((n) => n.userId == user.id && !n.isRead)
            .length;

        return WillPopScope(
          onWillPop: () async {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) =>
                  AlertDialog(
                    backgroundColor: AppTheme.cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text('Exit App', style: TextStyle(fontWeight: FontWeight
                            .bold)),
                      ],
                    ),
                    content: const Text(
                        'Are you sure you want to exit Social Booster?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(
                            color: AppTheme.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Exit', style: TextStyle(color: Colors
                            .white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
            );
            return shouldPop ?? false;
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: const Text(
                      'W',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Social Booster',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                // Coin Balance Display Removed

                // Notifications bell
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'about') {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            AlertDialog(
                              backgroundColor: AppTheme.cardBg,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: const Text('About Us'),
                              content: const Text(
                                  'Social Booster helps you boost your social media accounts and earn rewards by completing simple microtasks.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                    } else if (value == 'rate') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for rating us!'),
                          backgroundColor: AppTheme.secondary,
                        ),
                      );
                    } else if (value == 'share') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sharing link copied to clipboard!'),
                          backgroundColor: AppTheme.secondary,
                        ),
                      );
                    } else if (value == 'support') {
                      Navigator.pushNamed(context, '/support');
                    }
                  },
                  itemBuilder: (context) =>
                  [
                    const PopupMenuItem(
                      value: 'about',
                      child: Text('About Us'),
                    ),
                    const PopupMenuItem(
                      value: 'rate',
                      child: Text('Rate Us'),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Share App'),
                    ),
                    const PopupMenuItem(
                      value: 'support',
                      child: Text('Support'),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  activeIcon: Icon(Icons.work),
                  label: 'Work',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.campaign_outlined),
                  activeIcon: Icon(Icons.campaign),
                  label: 'Campaign',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
          );}
        );
      },
    );
  }
}
