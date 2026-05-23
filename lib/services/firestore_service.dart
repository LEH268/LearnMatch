import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ======================
  // STREAM STUDENTS
  // ======================
  Stream<QuerySnapshot> getStudentsStream() {
    return _db.collection('students').snapshots();
  }

  // ======================
  // STREAM TEACHERS
  // ======================
  Stream<QuerySnapshot> getTeachersStream() {
    return _db.collection('teachers').snapshots();
  }

  // ======================
  // STREAM CLASSES
  // ======================
  Stream<QuerySnapshot> getClassesStream() {
    return _db.collection('classes').snapshots();
  }
}