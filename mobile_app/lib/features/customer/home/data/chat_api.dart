import 'package:grocery_shopping_app/core/network/api_client.dart';

import 'chat_model.dart';

class ChatApi {
  Future<List<ConversationModel>> getConversations() async {
    final response = await ApiClient.dio.get('/chat/conversations');
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ConversationModel> createOrGetConversation(
      int orderId, int shipperId) async {
    final response = await ApiClient.dio.post(
      '/chat/conversations',
      queryParameters: {
        'orderId': orderId,
        'shipperId': shipperId,
      },
    );
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return ConversationModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Invalid conversation response');
  }

  Future<ConversationModel> getConversation(String conversationId) async {
    final response =
        await ApiClient.dio.get('/chat/conversations/$conversationId');
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return ConversationModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Invalid conversation response');
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response =
        await ApiClient.dio.get('/chat/conversations/$conversationId/messages');
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final response = await ApiClient.dio.post(
      '/chat/messages',
      data: {
        'conversationId': conversationId,
        'senderType': 'CUSTOMER',
        'content': content,
      },
    );
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return MessageModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Invalid message response');
  }
}
