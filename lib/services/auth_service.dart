import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// Return current user's role: 'admin' | 'teacher' | null
  static Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return doc.data()?['role'] as String?;
  }

  static Future<bool> isAdmin() async {
    return (await getCurrentUserRole()) == 'admin';
  }
}