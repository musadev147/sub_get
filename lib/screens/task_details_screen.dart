import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

import 'package:sub_get/services/firestore_service.dart';
import 'package:sub_get/services/auth_service.dart';
import 'package:sub_get/screens/webview_task_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> with WidgetsBindingObserver {
  late Campaign campaign;
  TaskAttempt? activeAttempt;
  
  String? _getYouTubeId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        if (uri.host.contains('youtu.be')) {
          return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        }
        if (uri.queryParameters.containsKey('v')) {
          return uri.queryParameters['v'];
        }
        if (uri.pathSegments.contains('embed')) {
          final index = uri.pathSegments.indexOf('embed');
          if (index + 1 < uri.pathSegments.length) {
            return uri.pathSegments[index + 1];
          }
        }
        if (uri.pathSegments.contains('v')) {
          final index = uri.pathSegments.indexOf('v');
          if (index + 1 < uri.pathSegments.length) {
            return uri.pathSegments[index + 1];
          }
        }
      }
    } catch (_) {}
    return null;
  }



  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 20,
      width: 1,
      color: AppTheme.border,
    );
  }
  
  bool _isTaskStarted = false;
  bool _isValidationReady = false;
  bool _isVerifying = false;
  bool _taskFailed = false;
  DateTime? _taskStartTime;
  int _secondsAccumulated = 0;
  Timer? _countdownTimer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    campaign = ModalRoute.of(context)!.settings.arguments as Campaign;
    if (!_isTaskStarted) {
      _timeLeft = campaign.stayTime;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Removed buggy AppLifecycleState tracking. 
  // We will track time absolutely since task start.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No-op
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_taskStartTime != null) {
        final elapsed = DateTime.now().difference(_taskStartTime!).inSeconds;
        setState(() {
          _timeLeft = (campaign.stayTime - elapsed).clamp(0, campaign.stayTime);
          if (_timeLeft <= 0) {
            _isValidationReady = true;
            _countdownTimer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _startTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebviewTaskScreen(campaign: campaign),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context); // Return to work tab if task was completed successfully
    }
  }

  void _verifyTask() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    setState(() {
      _isVerifying = true;
    });

    // Simulate verification delay (checking api completion status)
    await Future.delayed(const Duration(seconds: 2));

    // Save completion to Firebase!
    final success = await FirestoreService().completeTask(campaign, userId);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppTheme.cardBg,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.secondary,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Task Verified!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'You received +${campaign.rewardCoin} coins.',
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to Work page
                },
                child: const Text('Great!'),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _taskFailed = true;
        _isTaskStarted = false;
        _isValidationReady = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYouTube = campaign.type.toLowerCase().contains('youtube') ||
        campaign.link.contains('youtube') ||
        campaign.link.contains('youtu.be');
    final ytVideoId = isYouTube ? _getYouTubeId(campaign.link) : null;

    final isFacebook = campaign.type.toLowerCase().contains('facebook') ||
        campaign.link.contains('facebook.com') ||
        campaign.link.contains('fb.watch') ||
        campaign.link.contains('fb.gg');

    final hasStats = (isYouTube || isFacebook) && 
        (campaign.views != null || campaign.likes != null || campaign.comments != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFacebook) ...[
              Text(
                'Facebook Reel Preview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isTaskStarted ? null : _startTask,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1877F2), // Facebook Blue
                        Color(0xFF0C3D7E), // Darker Facebook Blue
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.15,
                        child: const Icon(
                          Icons.video_library_rounded,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF1877F2),
                          size: 36,
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.slideshow_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Watch Facebook Reel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${campaign.stayTime}s Required',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (isYouTube) ...[
              Text(
                'Video Preview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isTaskStarted ? null : _startTask,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    image: ytVideoId != null
                        ? DecorationImage(
                            image: NetworkImage('https://img.youtube.com/vi/$ytVideoId/hqdefault.jpg'),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Watch on YouTube',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${campaign.stayTime}s Required',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (hasStats) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (campaign.views != null) ...[
                      _buildStatItem(Icons.remove_red_eye_outlined, campaign.views!, 'Views'),
                    ],
                    if (campaign.views != null && (campaign.likes != null || campaign.comments != null)) _buildStatDivider(),
                    if (campaign.likes != null) ...[
                      _buildStatItem(Icons.thumb_up_outlined, campaign.likes!, 'Likes'),
                    ],
                    if (campaign.likes != null && campaign.comments != null) _buildStatDivider(),
                    if (campaign.comments != null) ...[
                      _buildStatItem(Icons.chat_bubble_outline_rounded, campaign.comments!, 'Comments'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          campaign.type,
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    campaign.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.monetization_on, color: AppTheme.accent),
                              const SizedBox(height: 4),
                              Text(
                                '${campaign.rewardCoin} Coins',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.timer_outlined, color: AppTheme.primaryLight),
                              const SizedBox(height: 4),
                              Text(
                                '${campaign.stayTime} Seconds',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Instructions
            Text(
              'Campaign Instructions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                campaign.instruction,
                style: const TextStyle(height: 1.5, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            // Interaction State Interface
            if (_isVerifying) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verifying task action on server...'),
                  ],
                ),
              ),
            ] else if (_isValidationReady) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.verified),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                ),
                onPressed: _verifyTask,
                label: const Text('Verify & Claim Coins'),
              ),
            ] else if (_isTaskStarted) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'STAY IN EXTERNAL APP',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryLight, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Timer: $_timeLeft seconds remaining',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Do NOT return to this app or close it before the timer completes, otherwise the task will fail.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (_taskFailed) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Task Failed! You returned too early. Please try again.',
                          style: TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                onPressed: _startTask,
                label: const Text('Start Task'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
