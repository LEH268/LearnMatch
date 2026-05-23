class StudentRecord {
  final String id;
  final String name;
  final bool hasSubmittedForm;
  final int? evaluationScore;
  final List<int>? detailedAnswers;

  StudentRecord({
    required this.id,
    required this.name,
    required this.hasSubmittedForm,
    this.evaluationScore,
    this.detailedAnswers,
  });
}