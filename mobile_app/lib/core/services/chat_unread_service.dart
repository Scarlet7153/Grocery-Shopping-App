import 'package:flutter/foundation.dart';
import 'package:grocery_shopping_app/features/customer/home/data/chat_api.dart';
import 'package:grocery_shopping_app/core/services/chat_websocket_service.dart';

class ChatUnreadService {
  ChatUnreadService._();
  static final ChatUnreadService instance = ChatUnreadService._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  bool _initialized = false;
  ConversationUpdateCallback? _convListener;
  final ChatApi _api = ChatApi();

  /// Initialize once: fetch conversations and subscribe to WS conversation list updates
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _refresh();

    final ws = ChatWebSocketService.instance;
    _convListener = () {
      _refresh();
    };
    ws.addConversationUpdateListener(_convListener!);

    try {
      await ws.connect();
      ws.subscribeToConversationList();
    } catch (_) {}
  }

  Future<void> _refresh() async {
    try {
      final convs = await _api.getConversations();
      final total = convs.fold<int>(0, (s, c) => s + (c.unreadCount));
      unreadCount.value = total;
    } catch (_) {
      // ignore errors silently
    }
  }

  /// Public refresh to force reloading unread counts
  Future<void> refresh() async => await _refresh();

  void dispose() {
    final ws = ChatWebSocketService.instance;
    if (_convListener != null) ws.removeConversationUpdateListener(_convListener!);
    _initialized = false;
  }
}
