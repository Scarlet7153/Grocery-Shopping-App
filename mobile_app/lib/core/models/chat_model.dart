class ConversationModel {
  final String id;
  final int orderId;
  final int shipperId;
  final int customerId;
  final String shipperName;
  final String? shipperAvatar;
  final String customerName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.orderId,
    required this.shipperId,
    required this.customerId,
    required this.shipperName,
    this.shipperAvatar,
    required this.customerName,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] ?? '') as String,
      orderId: (json['orderId'] ?? 0) as int,
      shipperId: (json['shipperId'] ?? 0) as int,
      customerId: (json['customerId'] ?? 0) as int,
      shipperName: (json['shipperName'] ?? '') as String,
      shipperAvatar: json['shipperAvatar'] as String?,
      customerName: (json['customerName'] ?? '') as String,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: (json['unreadCount'] ?? 0) as int,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final int senderId;
  final SenderType senderType;
  final String content;
  final DateTime timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.timestamp,
    required this.read,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? '') as String,
      conversationId: (json['conversationId'] ?? '') as String,
      senderId: (json['senderId'] ?? 0) as int,
      senderType: SenderType.values.firstWhere(
        (e) => e.name == (json['senderType'] ?? 'CUSTOMER'),
        orElse: () => SenderType.CUSTOMER,
      ),
      content: (json['content'] ?? '') as String,
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      read: (json['read'] ?? false) as bool,
    );
  }
}

enum SenderType { SHIPPER, CUSTOMER }
