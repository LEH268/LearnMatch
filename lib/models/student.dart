import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String className;
  final String emergencyContact;

  final String grades;
  final String basicInfo;
  final String specialConditions;

  final String aiCognitiveAnalysis;
  final String aiAdaptivePath;

  final Map<String, int> varkScores;
  final Map<String, int> personalityScores;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.emergencyContact,
    required this.grades,
    required this.basicInfo,
    required this.specialConditions,
    required this.aiCognitiveAnalysis,
    required this.aiAdaptivePath,
    this.varkScores = const {},
    this.personalityScores = const {},
  });

  // 添加从 Firestore 解析的方法
  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    return Student(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      className: data['className'] ?? 'Unassigned', // 如果没有分配班级则为 Unassigned
      emergencyContact: data['emergencyContact'] ?? '',
      grades: data['grades'] ?? '',
      basicInfo: data['basicInfo'] ?? '',
      specialConditions: data['specialConditions'] ?? '',
      aiCognitiveAnalysis: data['aiCognitiveAnalysis'] ?? '',
      aiAdaptivePath: data['aiAdaptivePath'] ?? '',
      // 安全地解析 Map
      varkScores: data['varkScores'] != null 
          ? Map<String, int>.from(data['varkScores']) 
          : {},
      personalityScores: data['cognitiveScores'] != null // 根据你的 service，这里存的是 cognitiveScores
          ? Map<String, int>.from(data['cognitiveScores']) 
          : {},
    );
  }

  // 判断学生是否已经提交测试 (如果有 vark 成绩代表已提交)
  bool get hasSubmitted => varkScores.isNotEmpty; 
}