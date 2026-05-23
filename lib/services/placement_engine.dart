import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════
// PLACEMENT RESULT MODEL
// ══════════════════════════════════════════════════

class PlacementResult {
  final String studentId;
  final String studentName;
  final String assignedClass;
  final String dominantStyle; // e.g. "Visual", "Auditory", etc.
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

  // ── VARK key → readable name + class name ──────
  static const Map<String, String> _varkLabel = {
    'V': 'Visual',
    'A': 'Auditory',
    'R': 'Read/Write',
    'K': 'Kinesthetic',
  };

  static const Map<String, String> _varkClass = {
    'V': 'Class V',
    'A': 'Class A',
    'R': 'Class R',
    'K': 'Class K',
  };

  // ── Determine dominant VARK style ──────────────
  static String getDominantStyle(Map<String, int> varkScores) {
    if (varkScores.isEmpty) return 'V'; // default fallback

    String dominant = 'V';
    int highest = -1;

    // Priority order if tied: V > A > R > K
    for (final key in ['V', 'A', 'R', 'K']) {
      final score = varkScores[key] ?? 0;
      if (score > highest) {
        highest = score;
        dominant = key;
      }
    }

    return dominant;
  }

  // ── Run placement for ALL unassigned students ──
  // Returns a list of PlacementResult for UI preview
  Future<List<PlacementResult>> runPlacement() async {
    final snapshot = await _db.collection('students').get();
    final results = <PlacementResult>[];

    // Track which classes are being created
    final Set<String> classesCreated = {};

    final WriteBatch batch = _db.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final varkRaw = data['varkScores'];

      // Skip if no VARK data
      if (varkRaw == null) continue;

      final varkScores = Map<String, int>.from(varkRaw);
      final dominant   = getDominantStyle(varkScores);
      final className  = _varkClass[dominant]!;
      final styleName  = _varkLabel[dominant]!;

      // 1. Update student's className in Firestore
      batch.update(doc.reference, {
        'className':     className,
        'dominantStyle': styleName,
        'placedAt':      FieldValue.serverTimestamp(),
      });

      classesCreated.add(className);

      results.add(PlacementResult(
        studentId:     doc.id,
        studentName:   data['name'] ?? 'Unknown',
        assignedClass: className,
        dominantStyle: styleName,
        varkScores:    varkScores,
      ));
    }

    // 2. Commit all student updates at once
    await batch.commit();

    // 3. Create / update each class document in 'classes' collection
    for (final className in classesCreated) {
      final varkKey  = _varkClass.entries
          .firstWhere((e) => e.value == className)
          .key;
      final students = results
          .where((r) => r.assignedClass == className)
          .map((r) => r.studentId)
          .toList();

      await _db.collection('classes').doc(className).set({
        'className':   className,
        'learningStyle': _varkLabel[varkKey],
        'studentIds':  students,
        'studentCount': students.length,
        'updatedAt':   FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return results;
  }

  // ── Preview placement WITHOUT saving ──────────
  // Useful to show teacher a preview before confirming
  Future<List<PlacementResult>> previewPlacement() async {
    final snapshot = await _db.collection('students').get();
    final results  = <PlacementResult>[];

    for (final doc in snapshot.docs) {
      final data    = doc.data();
      final varkRaw = data['varkScores'];
      if (varkRaw == null) continue;

      final varkScores = Map<String, int>.from(varkRaw);
      final dominant   = getDominantStyle(varkScores);

      results.add(PlacementResult(
        studentId:     doc.id,
        studentName:   data['name'] ?? 'Unknown',
        assignedClass: _varkClass[dominant]!,
        dominantStyle: _varkLabel[dominant]!,
        varkScores:    varkScores,
      ));
    }

    return results;
  }
}