import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/services/auth_service.dart';
import 'package:sub_get/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final db = MockDatabase();
    await db.init();
    await Future.delayed(const Duration(seconds: 2)); // Smooth branding duration
    
    if (!mounted) return;
    
    if (AuthService().currentUserId != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_outlined,
                    size: 80,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Social Booster',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Social Tasks & Micro Campaigns',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: AppTheme.border,
                    color: AppTheme.primary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
