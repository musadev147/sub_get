import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sub_get/mock_database.dart'; // To use the Campaign model for now

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get a stream of active campaigns
  Stream<List<Campaign>> getActiveCampaigns() {
    return _db
        .collection('campaigns')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Campaign(
          id: doc.id,
          title: data['title'] ?? '',
          link: data['link'] ?? '',
          type: data['type'] ?? '',
          rewardCoin: data['rewardCoin'] ?? 0,
          stayTime: data['stayTime'] ?? 0,
          instruction: data['instruction'] ?? '',
          status: data['status'] ?? 'active',
          createdBy: data['createdBy'] ?? '',
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
          totalWorkers: data['totalWorkers'] ?? 0,
          completedWorkers: data['completedWorkers'] ?? 0,
          views: data['views'] as String?,
          likes: data['likes'] as String?,
          comments: data['comments'] as String?,
        );
      }).toList();
    });
  }

  // Get a stream of campaigns created by a specific user
  Stream<List<Campaign>> getUserCampaigns(String userId) {
    return _db
        .collection('campaigns')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Campaign(
          id: doc.id,
          title: data['title'] ?? '',
          link: data['link'] ?? '',
          type: data['type'] ?? '',
          rewardCoin: data['rewardCoin'] ?? 0,
          stayTime: data['stayTime'] ?? 0,
          instruction: data['instruction'] ?? '',
          status: data['status'] ?? 'pending',
          createdBy: data['createdBy'] ?? '',
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
          totalWorkers: data['totalWorkers'] ?? 0,
          completedWorkers: data['completedWorkers'] ?? 0,
          views: data['views'] as String?,
          likes: data['likes'] as String?,
          comments: data['comments'] as String?,
        );
      }).toList();
    });
  }

  // Get a stream of campaign categories/tags
  Stream<List<String>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    });
  }

  // Create a new campaign
  Future<void> createCampaign(Campaign campaign) async {
    final docRef = _db.collection('campaigns').doc(); // Auto-generate ID
    await docRef.set({
      'title': campaign.title,
      'link': campaign.link,
      'type': campaign.type,
      'rewardCoin': campaign.rewardCoin,
      'stayTime': campaign.stayTime,
      'instruction': campaign.instruction,
      'status': campaign.status,
      'createdBy': campaign.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'totalWorkers': campaign.totalWorkers,
      'completedWorkers': campaign.completedWorkers,
      'views': campaign.views,
      'likes': campaign.likes,
      'comments': campaign.comments,
    });
  }

  // Delete a campaign
  Future<void> deleteCampaign(String campaignId) async {
    await _db.collection('campaigns').doc(campaignId).delete();
  }

  // Get a stream of user's withdrawal requests
  Stream<QuerySnapshot> getUserWithdrawals(String userId) {
    return _db
        .collection('withdrawals')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Submit a withdrawal request
  Future<void> requestWithdrawal({
    required String userId,
    required String userName,
    required String userEmail,
    required int amount,
    required String method,
    required String accountDetails,
  }) async {
    await _db.collection('withdrawals').add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'amount': amount,
      'method': method,
      'accountDetails': accountDetails,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  // Record a task attempt in Firebase
  Future<bool> completeTask(Campaign campaign, String workerId) async {
    try {
      // 1. Add attempt document
      await _db.collection('task_attempts').add({
        'campaignId': campaign.id,
        'workerId': workerId,
        'earnedCoin': campaign.rewardCoin,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment completedWorkers in campaign
      await _db.collection('campaigns').doc(campaign.id).update({
        'completedWorkers': FieldValue.increment(1),
      });

      // 3. Increment coins in user doc
      await _db.collection('users').doc(workerId).update({
        'coin': FieldValue.increment(campaign.rewardCoin),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Deduct coins from user balance
  Future<void> deductCoins(String userId, int amount) async {
    await _db.collection('users').doc(userId).update({
      'coin': FieldValue.increment(-amount),
    });
  }

  // Get a stream of completed campaign IDs for a specific user
  Stream<List<String>> getCompletedTaskIds(String workerId) {
    return _db
        .collection('task_attempts')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['campaignId'] as String).toList();
    });
  }



  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifs = snapshot.docs.map((doc) {
            final data = doc.data();
            return AppNotification(
              id: doc.id,
              userId: data['userId'] ?? '',
              title: data['title'] ?? '',
              body: data['body'] ?? '',
              createdAt: data['createdAt'] != null 
                  ? (data['createdAt'] as Timestamp).toDate() 
                  : DateTime.now(),
              isRead: data['isRead'] ?? false,
            );
          }).toList();
          
          notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifs;
        });
  }

  Future<void> markNotificationsRead(String userId) async {
    final unreadNotifs = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
        
    if (unreadNotifs.docs.isEmpty) return;
        
    final batch = _db.batch();
    for (var doc in unreadNotifs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // ==========================================
  // SUPPORT TICKETS
  // ==========================================

  Future<void> createSupportTicket(String userId, String userName, String userEmail, String category, String subject, String message) async {
    await _db.collection('support_tickets').add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'category': category,
      'subject': subject,
      'message': message,
      'status': 'pending',
      'reply': null,
      'repliedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<SupportTicket>> getUserSupportTickets(String userId) {
    return _db
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final tickets = snapshot.docs.map<SupportTicket>((doc) => _mapToSupportTicket(doc)).toList();
          tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tickets;
        });
  }

  Stream<List<SupportTicket>> getAllSupportTickets() {
    return _db
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map<SupportTicket>((doc) => _mapToSupportTicket(doc)).toList());
  }

  Future<void> adminReplyTicket(String ticketId, String replyMessage) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'status': 'resolved',
      'reply': replyMessage,
      'repliedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminDeleteTicket(String ticketId) async {
    await _db.collection('support_tickets').doc(ticketId).delete();
  }

  SupportTicket _mapToSupportTicket(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ticket = SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      category: data['category'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
    ticket.status = data['status'] ?? 'pending';
    ticket.reply = data['reply'];
    ticket.repliedAt = (data['repliedAt'] as Timestamp?)?.toDate();
    return ticket;
  }

  // Helper to seed categories if empty
  Future<void> seedCategoriesIfEmpty() async {
    final snapshot = await _db.collection('categories').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final defaultTags = [
        'Facebook Like',
        'Facebook Comment',
        'Facebook Share',
        'YouTube Watch',
        'YouTube Subscribe',
        'Website Visit',
        'Instagram Follow',
        'Instagram Like',
        'Twitter Follow',
        'TikTok Like',
        'Telegram Join',
      ];
      for (var tag in defaultTags) {
        await _db.collection('categories').add({'name': tag});
      }
    }
  }

  // Quick helper to seed dummy data if collection is empty
  Future<void> seedDummyCampaignsIfEmpty() async {
    final snapshot = await _db.collection('campaigns').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final dummyCampaigns = [
        {
          'title': 'Like this Facebook Post',
          'link': 'https://facebook.com',
          'type': 'Facebook Like',
          'rewardCoin': 100,
          'stayTime': 20,
          'instruction': '1. Click start.\n2. Like the linked post.\n3. Stay at least 20 seconds.\n4. Return and verify.',
          'status': 'active',
          'createdBy': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'totalWorkers': 100,
          'completedWorkers': 12,
          'views': '12.5K',
          'likes': '850',
          'comments': '120',
        },
        {
          'title': 'Subscribe & Like YouTube Video',
          'link': 'https://youtube.com',
          'type': 'YouTube Like',
          'rewardCoin': 150,
          'stayTime': 30,
          'instruction': '1. Open link in YouTube.\n2. Watch for 30s.\n3. Like and subscribe.\n4. Return to claim coin.',
          'status': 'active',
          'createdBy': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'totalWorkers': 50,
          'completedWorkers': 5,
          'views': '54.2K',
          'likes': '3.4K',
          'comments': '430',
        },
        {
          'title': 'Read Tech News Article',
          'link': 'https://google.com',
          'type': 'Website Visit',
          'rewardCoin': 50,
          'stayTime': 20,
          'instruction': '1. Visit the blog site.\n2. Scroll through the article.\n3. Wait 20 seconds.\n4. Return to app.',
          'status': 'active',
          'createdBy': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'totalWorkers': 200,
          'completedWorkers': 85,
        },
      ];

      for (var camp in dummyCampaigns) {
        await _db.collection('campaigns').add(camp);
      }
    }
  }
}
