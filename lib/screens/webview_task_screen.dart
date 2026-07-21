import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/auth_service.dart';
import 'package:sub_get/services/firestore_service.dart';

class WebviewTaskScreen extends StatefulWidget {
  final Campaign campaign;
  const WebviewTaskScreen({super.key, required this.campaign});

  @override
  State<WebviewTaskScreen> createState() => _WebviewTaskScreenState();
}

class _WebviewTaskScreenState extends State<WebviewTaskScreen> {
  late final WebViewController _controller;
  late final List<String> _playlist;
  int _currentIndex = 0;
  
  int _timeLeft = 0;
  Timer? _timer;
  bool _completed = false;
  bool _isVerifying = false;
  int _currentBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _playlist = (widget.campaign.links != null && widget.campaign.links!.isNotEmpty) 
        ? widget.campaign.links! 
        : [widget.campaign.link];
        
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      );

    _loadCurrentVideo();
    _fetchBalance();
  }

  void _loadCurrentVideo() {
    setState(() {
      _timeLeft = widget.campaign.stayTime;
      _isLoading = true;
    });
    
    String urlStr = _playlist[_currentIndex];
    // Auto-play the video if it's youtube by appending autoplay=1
    if (urlStr.contains('youtube.com') || urlStr.contains('youtu.be')) {
      if (urlStr.contains('?')) {
        urlStr += '&autoplay=1&mute=1';
      } else {
        urlStr += '?autoplay=1&mute=1';
      }
    }

    _controller.loadRequest(Uri.parse(urlStr));

    _timer?.cancel();
    _startTimer();
  }

  void _fetchBalance() async {
    final user = await AuthService().getUser();
    if (user != null && mounted) {
      setState(() {
        _currentBalance = user.coin;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        if (_currentIndex < _playlist.length - 1) {
          // Load next video in playlist
          _currentIndex++;
          _loadCurrentVideo();
        } else if (!_completed) {
          // Finished entire playlist
          _completeTask();
        }
      }
    });
  }

  Future<void> _completeTask() async {
    setState(() {
      _completed = true;
      _isVerifying = true;
    });

    final userId = AuthService().currentUserId;
    if (userId != null) {
      final success = await FirestoreService().completeTask(widget.campaign, userId);
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        if (success) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Column(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.secondary, size: 60),
                  SizedBox(height: 16),
                  Text('Task Completed!'),
                ],
              ),
              content: Text(
                'You watched all videos and earned ${widget.campaign.rewardCoin} coins.',
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Claim Reward'),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification failed or already completed.')),
          );
          Navigator.pop(context, false);
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_completed) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Cancel Task?'),
          content: const Text('If you leave now, you will lose your progress and not earn any coins for this task.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Watching', style: TextStyle(color: AppTheme.secondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Leave', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentUrl = _playlist[_currentIndex];
    final domain = Uri.parse(currentUrl).host.replaceFirst('www.', '');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E), // Dark app background
        body: SafeArea(
          child: Column(
            children: [
              // Browser-like Header
              Container(
                color: const Color(0xFF2D2D2D), // Dark grey browser bar
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home_outlined, color: Colors.white70),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF404040), // Address bar background
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                domain,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: () {
                        _controller.reload();
                      },
                    ),
                  ],
                ),
              ),
              // WebView Area
              Expanded(
                child: Stack(
                  children: [
                    AbsorbPointer(
                      absorbing: true,
                      child: WebViewWidget(controller: _controller),
                    ),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: AppTheme.secondary),
                      ),
                    if (_isVerifying)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppTheme.secondary),
                              SizedBox(height: 16),
                              Text(
                                'Verifying Completion...',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom UI (Matches User's Provided Image)
              Container(
                color: const Color(0xFFF5F5F5), // Light background for the bottom bar
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row of the bottom bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Text('Autoplay', style: TextStyle(color: Colors.black87, fontSize: 14)),
                          const SizedBox(width: 8),
                          // Custom toggle visual
                          Container(
                            width: 36,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.volume_up, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'SUBSCRIBE',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.campaign.rewardCoin}',
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: Colors.grey.withOpacity(0.3)),
                    // Bottom row of the bottom bar (Coins and Time)
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$_currentBalance',
                                  style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w300),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'coins',
                                  style: TextStyle(color: Colors.black54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 2, height: 40, color: Colors.redAccent),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$_timeLeft',
                                  style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w300),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'seconds',
                                  style: TextStyle(color: Colors.black54, fontSize: 14),
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
            ],
          ),
        ),
      ),
    );
  }
}
