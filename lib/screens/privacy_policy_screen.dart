import 'package:flutter/material.dart';
import 'package:sub_get/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppTheme.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.security_outlined,
                    size: 64,
                    color: AppTheme.primaryLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last Updated: August 2026',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'We are committed to protecting your personal data and your right to privacy. Please read our policy below to understand how we collect, use, and protect your information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Policy Sections Title
            const Text(
              'Policy Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Accordion-style cards
            _buildPolicySection(
              context,
              icon: Icons.info_outline,
              title: '1. Information We Collect',
              content: 'We collect personal information that you voluntarily provide to us when registering, such as your full name, email address, phone number, and profile picture. We also gather completion status of campaigns and transaction history related to wallet balances.',
            ),
            _buildPolicySection(
              context,
              icon: Icons.settings_suggest_outlined,
              title: '2. How We Use Your Info',
              content: 'We use the collected information to manage user accounts, authenticate identity via Firebase, process task completion proofs, issue reward coins, verify reward redemptions, and send important service-related notifications.',
            ),
            _buildPolicySection(
              context,
              icon: Icons.shield_outlined,
              title: '3. Data Sharing & Security',
              content: 'Your security is paramount. We do not sell or trade your personal data. We utilize industry-standard security services (such as Firebase Authentication and Google Cloud Storage) to safeguard data against unauthorized access.',
            ),
            _buildPolicySection(
              context,
              icon: Icons.cookie_outlined,
              title: '4. Third-Party Services',
              content: 'Our application integrates third-party tools, including Google Mobile Ads (AdMob) and Firebase Analytics, which may collect information used to identify you and display relevant advertisements.',
            ),
            _buildPolicySection(
              context,
              icon: Icons.delete_outline,
              title: '5. Data Deletion Rights',
              content: 'You hold the right to request deletion of your account and all associated personal data from our systems at any time. Simply reach out via the Support & Help Desk menu, and our team will handle your request promptly.',
            ),
            const SizedBox(height: 16),

            // Footer Contact Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'Have questions or concerns?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our support team is active 24/7 to resolve queries regarding your data protection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.help_outline, size: 20),
                    label: const Text('Contact Support'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/support');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primaryLight, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        iconColor: AppTheme.primaryLight,
        collapsedIconColor: AppTheme.textSecondary,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
