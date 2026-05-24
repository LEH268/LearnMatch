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

  // ======================
  // SAVE SPECIAL REQUEST
  // Match by name + className (case-insensitive) so the
  // request attaches to the SAME student record created by
  // the pre-admission test. If no match, create a stub doc
  // so the special-needs flag is still recorded somewhere.
  // ======================
  Future<void> submitSpecialRequest({
    required String studentName,
    required String className,
    required List<String> conditions,
    required String others,
  }) async {
    // "None" alone or empty conditions = no special needs
    bool hasSpecialNeeds =
        conditions.isNotEmpty && !conditions.contains("None");
    if (others.trim().isNotEmpty) hasSpecialNeeds = true;

    final payload = <String, dynamic>{
      'name': studentName,
      'className': className,
      'specialConditions': conditions,
      'specialConditionsOthers': others,
      'hasSpecialNeeds': hasSpecialNeeds,
      'specialRequestUpdatedAt': FieldValue.serverTimestamp(),
    };

    // 1) Try exact match: name + className (most specific)
    final exact = await _db
        .collection('students')
        .where('name', isEqualTo: studentName)
        .where('className', isEqualTo: className)
        .limit(1)
        .get();

    if (exact.docs.isNotEmpty) {
      await exact.docs.first.reference
          .set(payload, SetOptions(merge: true));
      return;
    }

    // 2) Fall back to name-only match (case-insensitive). Useful when
    //    pre-admission didn't ask for a class, or the parent typed a
    //    slightly different class name.
    final all = await _db.collection('students').get();
    QueryDocumentSnapshot<Map<String, dynamic>>? match;
    for (final doc in all.docs) {
      final n = (doc.data()['name'] ?? '').toString().trim();
      if (n.toLowerCase() == studentName.toLowerCase()) {
        match = doc;
        break;
      }
    }

    if (match != null) {
      await match.reference.set(payload, SetOptions(merge: true));
    } else {
      // 3) Last resort — create a stub so the special needs flag
      //    is still captured. Once the student finishes the
      //    pre-admission test their VARK data will merge in.
      await _db.collection('students').add({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}