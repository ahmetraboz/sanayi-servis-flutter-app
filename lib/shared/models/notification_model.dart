class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] as int,
    userId: json['userId'] as int,
    title: json['title'] as String,
    message: json['message'] as String,
    type: json['type'] as String,
    isRead: json['isRead'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };
}
