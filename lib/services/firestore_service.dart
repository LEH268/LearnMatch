import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// FIREBASE SERVICE
// ==========================================
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ======================
  // STREAMS (Dashboard use)
  // ======================
  Stream<QuerySnapshot> getStudentsStream() {
    return _db.collection('students').snapshots();
  }

  Stream<QuerySnapshot> getTeachersStream() {
    return _db.collection('teachers').snapshots();
  }

  Stream<QuerySnapshot> getClassesStream() {
    return _db.collection('classes').snapshots();
  }

  // ======================
  // SAVE TEST RESULT
  // ======================
  Future<void> saveStudentTestResult({
    required String name,
    required String emergencyContact,
    required Map<String, int> varkScores,
    required Map<String, int> cognitiveScores,
  }) async {
    await _db.collection('students').add({
      'name': name,
      'emergencyContact': emergencyContact,
      'varkScores': varkScores,
      'cognitiveScores': cognitiveScores,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}