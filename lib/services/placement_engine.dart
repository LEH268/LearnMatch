import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════
// PLACEMENT RESULT MODEL
// ══════════════════════════════════════════════════

class PlacementResult {
  final String studentId;
  final String studentName;
  final String assignedClass;
  final String dominantStyle;
  final Map<String, int> varkScores;

  PlacementResult({
    required this.studentId,
    required this.studentName,
    required this.assignedClass,
    required this.dominantStyle,
    required this.varkScores,
  });
}

// ══════════════════════════════════════════════════
// PLACEMENT ENGINE
// ══════════════════════════════════════════════════

class PlacementEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<String, String> _varkLabel = {
    'V': 'Visual',
    'A': 'Auditory',
    'R': 'Read/Write',
    'K': 'Kinesthetic',
  };

  // ── Determine dominant VARK style ──────────────
  static String getDominantStyle(Map<String, int> varkScores) {
    if (varkScores.isEmpty) return 'V';
    String dominant = 'V';
    int highest = -1;
    for (final key in ['V', 'A', 'R', 'K']) {
      final score = varkScores[key] ?? 0;
      if (score > highest) {
        highest = score;
        dominant = key;
      }
    }
    return dominant;
  }

  // ── Assign student to best matching class based on targetVARK ──
  static String _assignToClass(
    String dominant,
    List<Map<String, dynamic>> classes,
    Map<String, int> classCounts,
  ) {
    if (classes.isEmpty) return 'Unassigned';

    // 筛选出所有与学生主要学习风格（Dominant）相匹配的班级
    final matchingClasses = classes.where((c) => c['targetVARK'] == dominant).toList();

    // 如果没有找到匹配的班级，暂时列为未分配（或者你可以在此修改为随机分配）
    if (matchingClasses.isEmpty) {
      return 'Unassigned';
    }

    // 负载均衡：如果有多于一个班级适合（比如 Year1 和 Year2 都有 V 班），分配给人数最少的那个
    String minClass = matchingClasses.first['className'] as String;
    int minCount = classCounts[minClass] ?? 0;
    
    for (final c in matchingClasses) {
      final name = c['className'] as String;
      final count = classCounts[name] ?? 0;
      if (count < minCount) {
        minCount = count;
        minClass = name;
      }
    }
    return minClass;
  }

  // ── Preview placement WITHOUT saving ──────────
  Future<List<PlacementResult>> previewPlacement(
      List<Map<String, dynamic>> existingClasses) async {
    final snapshot = await _db.collection('students').get();
    final results = <PlacementResult>[];
    final classCounts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final varkRaw = data['varkScores'];
      if (varkRaw == null) continue;

      final varkScores = Map<String, int>.from(varkRaw);
      final dominant = getDominantStyle(varkScores);
      final className = _assignToClass(dominant, existingClasses, classCounts);
      
      if (className != 'Unassigned') {
        classCounts[className] = (classCounts[className] ?? 0) + 1;
      }

      results.add(PlacementResult(
        studentId: doc.id,
        studentName: data['name'] ?? 'Unknown',
        assignedClass: className,
        dominantStyle: _varkLabel[dominant] ?? dominant,
        varkScores: varkScores,
      ));
    }

    return results;
  }

  // ── Run placement and SAVE to Firestore ────────
  Future<List<PlacementResult>> runPlacement(
      List<Map<String, dynamic>> existingClasses) async {
    final snapshot = await _db.collection('students').get();
    final results = <PlacementResult>[];
    final classStudentMap = <String, List<String>>{};
    final classCounts = <String, int>{};

    final WriteBatch batch = _db.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final varkRaw = data['varkScores'];
      if (varkRaw == null) continue;

      final varkScores = Map<String, int>.from(varkRaw);
      final dominant = getDominantStyle(varkScores);
      final className = _assignToClass(dominant, existingClasses, classCounts);
      
      if (className != 'Unassigned') {
        classCounts[className] = (classCounts[className] ?? 0) + 1;
        classStudentMap.putIfAbsent(className, () => []).add(doc.id);
      }

      batch.update(doc.reference, {
        'className': className,
        'dominantStyle': _varkLabel[dominant] ?? dominant,
        'placedAt': FieldValue.serverTimestamp(),
      });

      results.add(PlacementResult(
        studentId: doc.id,
        studentName: data['name'] ?? 'Unknown',
        assignedClass: className,
        dominantStyle: _varkLabel[dominant] ?? dominant,
        varkScores: varkScores,
      ));
    }

    await batch.commit();

    // Update class documents with student counts
    for (final entry in classStudentMap.entries) {
      await _db.collection('classes').doc(entry.key).set({
        'className': entry.key,
        'studentIds': entry.value,
        'studentCount': entry.value.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return results;
  }
}