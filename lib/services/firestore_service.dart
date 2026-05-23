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
  // ======================
  Future<void> submitSpecialRequest({
    required String studentName,
    required String emergencyContact,
    required List<String> conditions,
    required String others,
  }) async {
    // 检查是否勾选了特殊需求（排除 None）
    bool hasSpecialNeeds = conditions.isNotEmpty && !conditions.contains("None");
    if (others.trim().isNotEmpty) {
      hasSpecialNeeds = true;
    }

    // 先通过学生名字寻找数据库里是否已有这个学生
    final query = await _db.collection('students').where('name', isEqualTo: studentName).get();

    if (query.docs.isNotEmpty) {
      // 如果学生已经存在，就更新他的资料，给他贴上特殊人群标签
      await _db.collection('students').doc(query.docs.first.id).update({
        'emergencyContact': emergencyContact,
        'specialConditions': conditions,
        'specialConditionsOthers': others,
        'hasSpecialNeeds': hasSpecialNeeds, // 标记为特殊人群
        'specialRequestUpdatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // 如果学生不存在，则创建一条新的学生记录
      await _db.collection('students').add({
        'name': studentName,
        'emergencyContact': emergencyContact,
        'specialConditions': conditions,
        'specialConditionsOthers': others,
        'hasSpecialNeeds': hasSpecialNeeds, // 标记为特殊人群
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}