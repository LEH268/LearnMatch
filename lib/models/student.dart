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
}