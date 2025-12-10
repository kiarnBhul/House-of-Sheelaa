class ReviewModel {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerified;
  final String? userId;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerified = false,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'userId': userId,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isVerified: json['isVerified'] ?? false,
      userId: json['userId'],
    );
  }
}
