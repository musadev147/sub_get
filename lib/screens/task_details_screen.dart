import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> with WidgetsBindingObserver {
  late Campaign campaign;
  TaskAttempt? activeAttempt;
  
  bool _isTaskStarted = false;
  bool _isValidationReady = false;
  bool _isVerifying = false;
  bool _taskFailed = false;

  DateTime? _suspendTime;
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

  // Monitor App Lifecycle to track focus duration
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isTaskStarted || _isValidationReady || _taskFailed) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _suspendTime = DateTime.now();
      _startCountdown();
    } else if (state == AppLifecycleState.resumed) {
      _countdownTimer?.cancel();
      if (_suspendTime != null) {
        final durationOut = DateTime.now().difference(_suspendTime!).inSeconds;
        setState(() {
          _secondsAccumulated += durationOut;
          _timeLeft = (campaign.stayTime - _secondsAccumulated).clamp(0, campaign.stayTime);
        });

        // If returned too early, fail task
        if (_secondsAccumulated < campaign.stayTime) {
          setState(() {
            _taskFailed = true;
            _isTaskStarted = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed! You returned before completing the required stay time.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          setState(() {
            _isValidationReady = true;
          });
        }
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  Future<void> _startTask() async {
    final uri = Uri.parse(campaign.link);
    
    // Register task in DB
    setState(() {
      activeAttempt = MockDatabase().startTask(campaign);
      _isTaskStarted = true;
      _secondsAccumulated = 0;
      _timeLeft = campaign.stayTime;
      _taskFailed = false;
      _isValidationReady = false;
    });

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch campaign link.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching link: $e')),
      );
    }
  }

  void _verifyTask() async {
    if (activeAttempt == null) return;

    setState(() {
      _isVerifying = true;
    });

    // Simulate verification delay (checking api completion status)
    await Future.delayed(const Duration(seconds: 2));

    final success = await MockDatabase().completeTask(activeAttempt!.id, _secondsAccumulated);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
