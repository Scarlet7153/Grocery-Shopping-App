class NotificationModel {
  final String id;          // MongoDB ObjectId String
  final int? recipientId;
  final String type;        // e.g. "ORDER_CREATED", "ORDER_CONFIRMED"
  final String title;
  final String body;
  final int? referenceId;   // orderId, reviewId...
  final String? referenceType; // "ORDER", "REVIEW"
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String? ?? '',   // MongoDB ObjectId String
        recipientId: (json['recipientId'] as num?)?.toInt(),
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        referenceId: (json['referenceId'] as num?)?.toInt(),
        referenceType: json['referenceType'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        'referenceId': referenceId,
        'referenceType': referenceType,
        'isRead': isRead,
        'createdAt': createdAt?.toIso8601String(),
      };

  NotificationModel copyWith({
    String? id,
    int? recipientId,
    String? type,
    String? title,
    String? body,
    int? referenceId,
    String? referenceType,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        recipientId: recipientId ?? this.recipientId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        referenceId: referenceId ?? this.referenceId,
        referenceType: referenceType ?? this.referenceType,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}
