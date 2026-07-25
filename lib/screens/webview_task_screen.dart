import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sub_get/mock_database.dart' hide AppUser;
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/auth_service.dart';
import 'package:sub_get/services/firestore_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebviewTaskScreen extends StatefulWidget {
  final Campaign campaign;
  final List<Campaign>? autoPlayCampaigns;
  final int autoPlayIndex;

  const WebviewTaskScreen({
    super.key, 
    required this.campaign,
    this.autoPlayCampaigns,
    this.autoPlayIndex = 0,
  });

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
  bool _isGoogleLoggedIn = true; // Start true to prevent flashing red banner while checking
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    
    _playlist = (widget.campaign.links != null && widget.campaign.links!.isNotEmpty) 
        ? widget.campaign.links! 
        : [widget.campaign.link];
        
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LoginChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          if (mounted && message.message == 'force_logout') {
            if (_isGoogleLoggedIn) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('webview_google_logged_in', false);
              setState(() {
                _isGoogleLoggedIn = false;
              });
              // Send them back to login page
              _controller.loadRequest(Uri.parse('https://accounts.google.com/ServiceLogin?continue=https://m.youtube.com'));
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              // Check if they successfully logged in and redirected back
              if (!_isGoogleLoggedIn && (url.startsWith('https://m.youtube.com') || url.startsWith('https://www.youtube.com'))) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('webview_google_logged_in', true);
                setState(() {
                  _isGoogleLoggedIn = true;
                });
                _loadCurrentVideo(); // Load the actual task video now!
              }

              // Periodically check if session expired while browsing
              _controller.runJavaScript('''
                setInterval(function() {
                  try {
                    var isGoogleOrYoutube = window.location.hostname.includes('google.com') || window.location.hostname.includes('youtube.com') || window.location.hostname.includes('youtu.be');
                    if (isGoogleOrYoutube) {
                      var isLoggedOut = false;
                      var links = document.querySelectorAll('a');
                      for (var i = 0; i < links.length; i++) {
                        if (links[i].href.includes('ServiceLogin')) {
                          isLoggedOut = true;
                          break;
                        }
                      }
                      if (isLoggedOut) {
                        LoginChannel.postMessage('force_logout');
                      }
                    }
                  } catch(e) {}
                }, 3000);
              ''');
            }
          },
        ),
      );

    _checkInitialLoginState();
    _fetchBalance();
  }

  Future<void> _checkInitialLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLogged = prefs.getBool('webview_google_logged_in') ?? false;
    
    if (mounted) {
      setState(() {
        _isGoogleLoggedIn = isLogged;
      });
      
      if (!isLogged) {
        // Force them to the Google Login page first.
        _controller.loadRequest(Uri.parse('https://accounts.google.com/ServiceLogin?continue=https://m.youtube.com'));
      } else {
        // Already logged in, load the task video
        _loadCurrentVideo();
      }
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      // Test Ad Unit ID for Rewarded Ad
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', 
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void _showRewardedAdAndComplete() {
    if (_rewardedAd == null) {
      debugPrint('Ad not ready yet. Completing task normally.');
      _completeTask();
      return;
    }
    
    // Pause timer since they are watching an ad
    _timer?.cancel();
    bool earnedReward = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Load the next one
        if (earnedReward) {
          _completeTask();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You must watch the full ad to earn coins!'), backgroundColor: Colors.redAccent),
            );
          }
          // Resume timer if they didn't finish the ad, so they can try again
          _startTimer();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _completeTask();
      },
    );
    
    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      earnedReward = true;
    });
  }

  void _loadCurrentVideo() {
    setState(() {
      _timeLeft = widget.campaign.stayTime;
      _isLoading = true;
    });
    
    String urlStr = _playlist[_currentIndex];
    // Auto-play the video if it's youtube by appending autoplay=1, ONLY if logged in
    if (urlStr.contains('youtube.com') || urlStr.contains('youtu.be')) {
      if (_isGoogleLoggedIn) {
        if (urlStr.contains('?')) {
          urlStr += '&autoplay=1&mute=1';
        } else {
          urlStr += '?autoplay=1&mute=1';
        }
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
      if (!_isGoogleLoggedIn) return; // Pause timer if not logged in
      
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        
        // Auto-click subscribe button in the webview when time is up
        _controller.runJavaScript('''
          try {
            var subBtn = document.querySelector('ytm-subscribe-button-renderer button') || 
                         document.querySelector('.yt-spec-button-shape-next--filled') || 
                         document.querySelector('[aria-label*="Subscribe"]') ||
                         document.querySelector('ytd-subscribe-button-renderer button');
            if (subBtn) {
              subBtn.click();
            }
          } catch(e) {}
        ''');

        // Wait a little bit for the subscribe action to register before completing or navigating
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (_currentIndex < _playlist.length - 1) {
            // Load next video in playlist
            _currentIndex++;
            _loadCurrentVideo();
          } else if (!_completed) {
            // Finished entire playlist
            _completeTask();
          }
        });
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
          if (widget.autoPlayCampaigns != null && widget.autoPlayIndex < widget.autoPlayCampaigns!.length - 1) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Task Completed! Earned ${widget.campaign.rewardCoin} coins. Starting next task...'), backgroundColor: Colors.green),
             );
             Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                   builder: (context) => WebviewTaskScreen(
                      campaign: widget.autoPlayCampaigns![widget.autoPlayIndex + 1],
                      autoPlayCampaigns: widget.autoPlayCampaigns,
                      autoPlayIndex: widget.autoPlayIndex + 1,
                   ),
                ),
             );
          } else {
             bool isAutoPlayEnd = widget.autoPlayCampaigns != null;
             showDialog(
               context: context,
               barrierDismissible: false,
               builder: (context) => AlertDialog(
                 backgroundColor: AppTheme.cardBg,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 title: Column(
                   children: [
                     const Icon(Icons.check_circle, color: AppTheme.secondary, size: 60),
                     const SizedBox(height: 16),
                     Text(isAutoPlayEnd ? 'Auto Work Complete!' : 'Task Completed!'),
                   ],
                 ),
                 content: Text(
                   isAutoPlayEnd 
                     ? 'You have successfully completed all available tasks in this category!'
                     : 'You watched all videos and earned ${widget.campaign.rewardCoin} coins.',
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
                       child: const Text('Great!'),
                     ),
                   ),
                 ],
               ),
             );
          }
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
    _rewardedAd?.dispose();
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
                    WebViewWidget(controller: _controller),
                    if (!_isGoogleLoggedIn)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: const Text(
                            'Please sign in to your Google account to continue and start the timer.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (!(currentUrl.contains('youtube.com') || currentUrl.contains('youtu.be')))
                      Positioned(
                        bottom: 24,
                        right: 24,
                        child: FloatingActionButton.extended(
                          onPressed: _showRewardedAdAndComplete,
                          backgroundColor: AppTheme.secondary,
                          icon: const Icon(Icons.remove_red_eye),
                          label: const Text('See More', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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
                          if (currentUrl.contains('youtube.com') || currentUrl.contains('youtu.be')) ...[
                            Icon(Icons.volume_up, color: _timeLeft == 0 ? Colors.green : Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _timeLeft == 0 ? 'SUBSCRIBED' : 'SUBSCRIBE',
                              style: TextStyle(color: _timeLeft == 0 ? Colors.green : Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(width: 12),
                          ],
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
