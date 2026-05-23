import 'package:learn_match/models/student_record.dart';

class FakeDatabase {
  // 🔥 这里是“数据库主表”
  static List<StudentRecord> students = [];

  // 🟢 可选：debug 用（看有没有数据）
  static void printAllStudents() {
    for (var s in students) {
      print("ID: ${s.id}, Name: ${s.name}, Score: ${s.evaluationScore}");
    }
  }

  // 🟢 可选：清空数据库（测试用）
  static void clear() {
    students.clear();
  }
}