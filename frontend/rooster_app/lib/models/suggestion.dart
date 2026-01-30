/// Represents a suggested volunteer assignment
class Suggestion {
  final String userId;
  final String userName;
  final double score;
  final String reasoning;

  Suggestion({
    required this.userId,
    required this.userName,
    required this.score,
    required this.reasoning,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'score': score,
      'reasoning': reasoning,
    };
  }
}
