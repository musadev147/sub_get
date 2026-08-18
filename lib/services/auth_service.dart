import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int coin;
  final String? imageBase64;
  final String status;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.coin,
    this.imageBase64,
    this.status = 'active',
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    int parseCoin(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }
    return AppUser(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      coin: parseCoin(data['coin']),
      imageBase64: data['imageBase64'],
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'coin': coin,
      'imageBase64': imageBase64,
    };
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of Auth State changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user document stream
  Stream<AppUser?> getUserStream() {
    if (currentUserId == null) return Stream.value(null);
    return _db.collection('users').doc(currentUserId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Get single user record
  Future<AppUser?> getUser() async {
    if (currentUserId == null) return null;
    final doc = await _db.collection('users').doc(currentUserId).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Get user by arbitrary ID
  Future<AppUser?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Sign up
  Future<AppUser?> signUpWithEmailPassword(String name, String email, String phone, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (credential.user != null) {
        final newUser = AppUser(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          coin: 500, // Initial coins
        );

        await _db.collection('users').doc(credential.user!.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Login
  Future<void> loginWithEmailPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Update profile
  Future<void> updateProfile(String name, String phone, {String? imageBase64}) async {
    if (currentUserId == null) return;
    final data = {
      'name': name,
      'phone': phone,
    };
    if (imageBase64 != null) {
      data['imageBase64'] = imageBase64;
    }
    await _db.collection('users').doc(currentUserId).update(data);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
