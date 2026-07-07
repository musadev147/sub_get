import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MODELS ---

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  int coin;
  String status; // 'active', 'blocked'
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.coin,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'coin': coin,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        coin: json['coin'],
        status: json['status'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Campaign {
  final String id;
  final String title;
  final String link;
  final String type; // 'Facebook Like', 'YouTube Watch', etc.
  final int rewardCoin;
  final int stayTime; // seconds
  final String instruction;
  String status; // 'pending', 'active', 'rejected'
  final String createdBy;
  final DateTime createdAt;
  final int totalWorkers;
  int completedWorkers;

  Campaign({
    required this.id,
    required this.title,
    required this.link,
    required this.type,
    required this.rewardCoin,
    required this.stayTime,
    required this.instruction,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.totalWorkers,
    this.completedWorkers = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'link': link,
        'type': type,
        'rewardCoin': rewardCoin,
        'stayTime': stayTime,
        'instruction': instruction,
        'status': status,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'totalWorkers': totalWorkers,
        'completedWorkers': completedWorkers,
      };

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'],
        title: json['title'],
        link: json['link'],
        type: json['type'],
        rewardCoin: json['rewardCoin'],
        stayTime: json['stayTime'],
        instruction: json['instruction'],
        status: json['status'],
        createdBy: json['createdBy'],
        createdAt: DateTime.parse(json['createdAt']),
        totalWorkers: json['totalWorkers'],
        completedWorkers: json['completedWorkers'] ?? 0,
      );
}

class TaskAttempt {
  final String id;
  final String campaignId;
  final String workerId;
  String status; // 'pending', 'completed', 'failed'
  final DateTime startTime;
  DateTime? finishTime;
  int staySeconds;
  final int rewardCoin;
  bool verified;

  TaskAttempt({
    required this.id,
    required this.campaignId,
    required this.workerId,
    required this.status,
    required this.startTime,
    this.finishTime,
    required this.staySeconds,
    required this.rewardCoin,
    required this.verified,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignId': campaignId,
        'workerId': workerId,
        'status': status,
        'startTime': startTime.toIso8601String(),
        'finishTime': finishTime?.toIso8601String(),
        'staySeconds': staySeconds,
        'rewardCoin': rewardCoin,
        'verified': verified,
      };

  factory TaskAttempt.fromJson(Map<String, dynamic> json) => TaskAttempt(
        id: json['id'],
        campaignId: json['campaignId'],
        workerId: json['workerId'],
        status: json['status'],
        startTime: DateTime.parse(json['startTime']),
        finishTime: json['finishTime'] != null ? DateTime.parse(json['finishTime']) : null,
        staySeconds: json['staySeconds'],
        rewardCoin: json['rewardCoin'],
        verified: json['verified'],
      );
}

class WalletTransaction {
  final String id;
  final String userId;
  final int coin;
  final String type; // 'reward', 'withdraw_request', 'withdraw_approved', 'withdraw_rejected', 'campaign_create', 'campaign_refund'
  final String description;
  final DateTime createdAt;
  String status; // 'pending', 'approved', 'rejected', 'completed'
  final String? withdrawMethod;
  final String? withdrawAccount;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.coin,
    required this.type,
    required this.description,
    required this.createdAt,
    this.status = 'completed',
    this.withdrawMethod,
    this.withdrawAccount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'coin': coin,
        'type': type,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'withdrawMethod': withdrawMethod,
        'withdrawAccount': withdrawAccount,
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'],
        userId: json['userId'],
        coin: json['coin'],
        type: json['type'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        status: json['status'] ?? 'completed',
        withdrawMethod: json['withdrawMethod'],
        withdrawAccount: json['withdrawAccount'],
      );
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        body: json['body'],
        createdAt: DateTime.parse(json['createdAt']),
        isRead: json['isRead'] ?? false,
      );
}

// --- DATABASE & STATE MANAGER ---

class MockDatabase extends ChangeNotifier {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal();

  AppUser? _currentUser;
  List<Campaign> _campaigns = [];
  List<TaskAttempt> _tasks = [];
  List<WalletTransaction> _transactions = [];
  List<AppNotification> _notifications = [];

  // Global Admin Settings
  int minWithdrawCoins = 1000; 
  int adminGlobalTimer = 20; // Default stay time in seconds

  AppUser? get currentUser => _currentUser;
  List<Campaign> get campaigns => _campaigns;
  List<TaskAttempt> get tasks => _tasks;
  List<WalletTransaction> get transactions => _transactions;
  List<AppNotification> get notifications => _notifications;

  bool get isAdmin => _currentUser?.email.toLowerCase() == 'admin@admin.com';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load User
    final userStr = prefs.getString('user');
    if (userStr != null) {
      _currentUser = AppUser.fromJson(json.decode(userStr));
    }

    // Load Campaigns
    final campaignsStr = prefs.getString('campaigns');
    if (campaignsStr != null) {
      final List dec = json.decode(campaignsStr);
      _campaigns = dec.map((e) => Campaign.fromJson(e)).toList();
    } else {
      _loadSeedCampaigns();
    }

    // Load Tasks
    final tasksStr = prefs.getString('tasks');
    if (tasksStr != null) {
      final List dec = json.decode(tasksStr);
      _tasks = dec.map((e) => TaskAttempt.fromJson(e)).toList();
    }

    // Load Transactions
    final transStr = prefs.getString('transactions');
    if (transStr != null) {
      final List dec = json.decode(transStr);
      _transactions = dec.map((e) => WalletTransaction.fromJson(e)).toList();
    }

    // Load Notifications
    final notifsStr = prefs.getString('notifications');
    if (notifsStr != null) {
      final List dec = json.decode(notifsStr);
      _notifications = dec.map((e) => AppNotification.fromJson(e)).toList();
    }

    // Global settings
    minWithdrawCoins = prefs.getInt('minWithdrawCoins') ?? 1000;
    adminGlobalTimer = prefs.getInt('adminGlobalTimer') ?? 20;

    notifyListeners();
  }

  void _loadSeedCampaigns() {
    _campaigns = [
      Campaign(
        id: 'c1',
        title: 'Like this Facebook Post',
        link: 'https://facebook.com',
        type: 'Facebook Like',
        rewardCoin: 100,
        stayTime: 20,
        instruction: '1. Click start.\n2. Like the linked post.\n3. Stay at least 20 seconds.\n4. Return and verify.',
        status: 'active',
        createdBy: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        totalWorkers: 100,
        completedWorkers: 12,
      ),
      Campaign(
        id: 'c2',
        title: 'Subscribe & Like YouTube Video',
        link: 'https://youtube.com',
        type: 'YouTube Like',
        rewardCoin: 150,
        stayTime: 30,
        instruction: '1. Open link in YouTube.\n2. Watch for 30s.\n3. Like and subscribe.\n4. Return to claim coin.',
        status: 'active',
        createdBy: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        totalWorkers: 50,
        completedWorkers: 5,
      ),
      Campaign(
        id: 'c3',
        title: 'Read Tech News Article',
        link: 'https://google.com',
        type: 'Website Visit',
        rewardCoin: 50,
        stayTime: 20,
        instruction: '1. Visit the blog site.\n2. Scroll through the article.\n3. Wait 20 seconds.\n4. Return to app.',
        status: 'active',
        createdBy: 'admin',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        totalWorkers: 200,
        completedWorkers: 85,
      ),
      Campaign(
        id: 'c4',
        title: 'Share Facebook Group Post',
        link: 'https://facebook.com',
        type: 'Facebook Share',
        rewardCoin: 200,
        stayTime: 45,
        instruction: '1. Open link.\n2. Share post to your timeline.\n3. Keep tab active for 45 seconds.\n4. Return to app.',
        status: 'active',
        createdBy: 'admin',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        totalWorkers: 30,
        completedWorkers: 2,
      ),
    ];
    _saveCampaigns();
  }

  // --- PERSISTENCE ---

  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser == null) {
      await prefs.remove('user');
    } else {
      await prefs.setString('user', json.encode(_currentUser!.toJson()));
    }
  }

  Future<void> _saveCampaigns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('campaigns', json.encode(_campaigns.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', json.encode(_tasks.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transactions', json.encode(_transactions.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', json.encode(_notifications.map((e) => e.toJson()).toList()));
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minWithdrawCoins', minWithdrawCoins);
    await prefs.setInt('adminGlobalTimer', adminGlobalTimer);
  }

  // --- USER AUTHENTICATION ---

  Future<void> login(String name, String email, String phone) async {
    if (email.toLowerCase() == 'admin@admin.com') {
      _currentUser = AppUser(
        id: 'admin',
        name: 'App Administrator',
        email: email,
        phone: phone.isEmpty ? '01700000000' : phone,
        coin: 999999,
        status: 'active',
        createdAt: DateTime.now(),
      );
    } else {
      _currentUser = AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        coin: 500, // starting gift coins
        status: 'active',
        createdAt: DateTime.now(),
      );
    }
    await _saveUser();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    await _saveUser();
    notifyListeners();
  }

  // --- TASK FLOWS ---

  TaskAttempt startTask(Campaign campaign) {
    if (_currentUser == null) throw Exception('Not logged in');
    final attempt = TaskAttempt(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      campaignId: campaign.id,
      workerId: _currentUser!.id,
      status: 'pending',
      startTime: DateTime.now(),
      staySeconds: 0,
      rewardCoin: campaign.rewardCoin,
      verified: false,
    );
    _tasks.add(attempt);
    _saveTasks();
    notifyListeners();
    return attempt;
  }

  Future<bool> completeTask(String taskId, int actualStaySeconds) async {
    if (_currentUser == null) return false;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return false;

    final task = _tasks[taskIndex];
    final campaignIndex = _campaigns.indexWhere((c) => c.id == task.campaignId);
    if (campaignIndex == -1) return false;

    final campaign = _campaigns[campaignIndex];

    if (actualStaySeconds < campaign.stayTime) {
      task.status = 'failed';
      task.finishTime = DateTime.now();
      task.staySeconds = actualStaySeconds;
      await _saveTasks();
      notifyListeners();
      return false;
    }

    task.status = 'completed';
    task.finishTime = DateTime.now();
    task.staySeconds = actualStaySeconds;
    task.verified = true;

    _currentUser!.coin += task.rewardCoin;
    await _saveUser();

    campaign.completedWorkers += 1;
    await _saveCampaigns();

    final transaction = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.id,
      coin: task.rewardCoin,
      type: 'reward',
      description: 'Reward for task: ${campaign.title}',
      createdAt: DateTime.now(),
    );
    _transactions.add(transaction);
    await _saveTransactions();

    addNotification(
      _currentUser!.id,
      'Task Completed Successfully',
      'You earned ${task.rewardCoin} coins from: ${campaign.title}',
    );

    await _saveTasks();
    notifyListeners();
    return true;
  }

  // --- CAMPAIGN MANAGEMENT ---

  Future<void> createCampaign({
    required String title,
    required String link,
    required String type,
    required int rewardCoin,
    required int totalWorkers,
    required int stayTime,
    required String instruction,
  }) async {
    if (_currentUser == null) throw Exception('Not logged in');

    final cost = rewardCoin * totalWorkers;
    if (_currentUser!.coin < cost && !isAdmin) {
      throw Exception('Insufficient Coins! Required: $cost, Available: ${_currentUser!.coin}');
    }

    if (!isAdmin) {
      _currentUser!.coin -= cost;
      await _saveUser();
    }

    final campaign = Campaign(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      link: link,
      type: type,
      rewardCoin: rewardCoin,
      stayTime: stayTime,
      instruction: instruction,
      status: isAdmin ? 'active' : 'pending',
      createdBy: _currentUser!.id,
      createdAt: DateTime.now(),
      totalWorkers: totalWorkers,
    );

    _campaigns.add(campaign);
    await _saveCampaigns();

    final transaction = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.id,
      coin: cost,
      type: 'campaign_create',
      description: 'Created Campaign: $title',
      createdAt: DateTime.now(),
    );
    _transactions.add(transaction);
    await _saveTransactions();

    addNotification(
      _currentUser!.id,
      'Campaign Submitted',
      'Your campaign "$title" is submitted for Admin review.',
    );

    notifyListeners();
  }

  // --- WITHDRAW SYSTEM ---

  Future<void> requestWithdraw({
    required int coinAmount,
    required String method,
    required String accountDetails,
  }) async {
    if (_currentUser == null) throw Exception('Not logged in');
    if (coinAmount < minWithdrawCoins) {
      throw Exception('Minimum withdraw limit is $minWithdrawCoins coins.');
    }
    if (_currentUser!.coin < coinAmount) {
      throw Exception('Insufficient balance to withdraw.');
    }

    _currentUser!.coin -= coinAmount;
    await _saveUser();

    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.id,
      coin: coinAmount,
      type: 'withdraw_request',
      description: 'Withdraw Request via $method',
      createdAt: DateTime.now(),
      status: 'pending',
      withdrawMethod: method,
      withdrawAccount: accountDetails,
    );

    _transactions.add(tx);
    await _saveTransactions();

    addNotification(
      _currentUser!.id,
      'Withdraw Requested',
      'Your request for $coinAmount coins via $method is processing.',
    );

    notifyListeners();
  }

  // --- NOTIFICATIONS ---

  void addNotification(String userId, String title, String body) {
    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    _saveNotifications();
  }

  void markNotificationsRead() {
    for (var n in _notifications) {
      if (n.userId == _currentUser?.id) {
        n.isRead = true;
      }
    }
    _saveNotifications();
    notifyListeners();
  }

  // --- ADMIN ACTIONS ---

  Future<void> adminApproveCampaign(String campaignId) async {
    final idx = _campaigns.indexWhere((c) => c.id == campaignId);
    if (idx != -1) {
      _campaigns[idx].status = 'active';
      await _saveCampaigns();
      
      addNotification(
        _campaigns[idx].createdBy,
        'Campaign Approved',
        'Your campaign "${_campaigns[idx].title}" has been approved and is now active.',
      );
      notifyListeners();
    }
  }

  Future<void> adminRejectCampaign(String campaignId) async {
    final idx = _campaigns.indexWhere((c) => c.id == campaignId);
    if (idx != -1) {
      final campaign = _campaigns[idx];
      campaign.status = 'rejected';
      await _saveCampaigns();

      final cost = campaign.rewardCoin * campaign.totalWorkers;
      final refundTx = WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: campaign.createdBy,
        coin: cost,
        type: 'campaign_refund',
        description: 'Refund for rejected campaign: ${campaign.title}',
        createdAt: DateTime.now(),
      );
      _transactions.add(refundTx);
      await _saveTransactions();

      if (_currentUser != null && _currentUser!.id == campaign.createdBy) {
        _currentUser!.coin += cost;
        await _saveUser();
      }

      addNotification(
        campaign.createdBy,
        'Campaign Rejected',
        'Your campaign "${campaign.title}" was rejected. $cost coins have been refunded.',
      );
      notifyListeners();
    }
  }

  Future<void> adminApproveWithdraw(String txId) async {
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx != -1) {
      _transactions[idx].status = 'approved';
      await _saveTransactions();

      addNotification(
        _transactions[idx].userId,
        'Withdraw Approved 🎉',
        'Your withdraw request of ${_transactions[idx].coin} coins via ${_transactions[idx].withdrawMethod} was approved.',
      );
      notifyListeners();
    }
  }

  Future<void> adminRejectWithdraw(String txId) async {
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx != -1) {
      final tx = _transactions[idx];
      tx.status = 'rejected';
      await _saveTransactions();

      if (_currentUser != null && _currentUser!.id == tx.userId) {
        _currentUser!.coin += tx.coin;
        await _saveUser();
      }

      final refund = WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        userId: tx.userId,
        coin: tx.coin,
        type: 'refund',
        description: 'Refund for rejected withdraw request',
        createdAt: DateTime.now(),
      );
      _transactions.add(refund);
      await _saveTransactions();

      addNotification(
        tx.userId,
        'Withdraw Rejected ❌',
        'Your withdraw request of ${tx.coin} coins was rejected and coins refunded.',
      );
      notifyListeners();
    }
  }

  Future<void> adminSetGlobalSettings(int minWithdraw, int timerSeconds) async {
    minWithdrawCoins = minWithdraw;
    adminGlobalTimer = timerSeconds;
    await saveSettings();
    notifyListeners();
  }

  Future<void> adminBlockUser(String userId, bool block) async {
    if (userId == 'admin') return;
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser!.status = block ? 'blocked' : 'active';
      await _saveUser();
    }
    notifyListeners();
  }
}
