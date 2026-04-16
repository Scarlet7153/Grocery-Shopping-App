import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/app_constants.dart';
import '../models/chat_model.dart';

typedef MessageCallback = void Function(MessageModel message);
typedef ConversationUpdateCallback = void Function();

class ChatWebSocketService {
  static ChatWebSocketService? _instance;
  StompClient? _stompClient;
  final String _baseUrl;

  final Map<String, StompUnsubscribe> _conversationSubscriptions = {};
  StompUnsubscribe? _conversationListSubscription;

  MessageCallback? onMessageReceived;
  ConversationUpdateCallback? onConversationUpdated;
  VoidCallback? onConnected;
  VoidCallback? onDisconnected;
  VoidCallback? onError;

  bool get isConnected => _stompClient?.connected ?? false;

  ChatWebSocketService._internal(this._baseUrl);

  static ChatWebSocketService get instance {
    _instance ??= ChatWebSocketService._internal(_getWebSocketUrl());
    return _instance!;
  }

  static String _getWebSocketUrl() {
    final baseUrl = AppConstants.baseUrl;
    final uri = Uri.parse(baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '$wsScheme://${uri.host}$portPart/ws';
  }

  void connect({String? authToken}) {
    if (_stompClient != null && _stompClient!.connected) {
      debugPrint('ChatWebSocketService: Already connected');
      return;
    }

    debugPrint('ChatWebSocketService: Connecting to $_baseUrl');

    final headers = <String, String>{};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: _baseUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: _onWebSocketError,
        onStompError: _onStompError,
        onUnhandledFrame: _onUnhandledFrame,
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('ChatWebSocketService: Connected');
    onConnected?.call();
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('ChatWebSocketService: Disconnected');
    _clearSubscriptions();
    onDisconnected?.call();
  }

  void _onWebSocketError(dynamic error) {
    debugPrint('ChatWebSocketService: WebSocket error: $error');
    onError?.call();
  }

  void _onStompError(StompFrame frame) {
    debugPrint('ChatWebSocketService: STOMP error: ${frame.body}');
    onError?.call();
  }

  void _onUnhandledFrame(StompFrame frame) {
    debugPrint('ChatWebSocketService: Unhandled frame: ${frame.command}');
  }

  void subscribeToConversation(String conversationId) {
    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint('ChatWebSocketService: Cannot subscribe - not connected');
      return;
    }

    if (_conversationSubscriptions.containsKey(conversationId)) {
      debugPrint('ChatWebSocketService: Already subscribed to $conversationId');
      return;
    }

    debugPrint(
        'ChatWebSocketService: Subscribing to conversation $conversationId');

    final subscription = _stompClient!.subscribe(
      destination: '/topic/chat/conversation/$conversationId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = Map<String, dynamic>.from(
              Uri.splitQueryString(frame.body!).map(
                (key, value) => MapEntry(key, _parseValue(value)),
              ),
            );
            final message = MessageModel.fromJson(json);
            onMessageReceived?.call(message);
          } catch (e) {
            debugPrint('ChatWebSocketService: Error parsing message: $e');
          }
        }
      },
    );

    _conversationSubscriptions[conversationId] = subscription;
  }

  void unsubscribeFromConversation(String conversationId) {
    final subscription = _conversationSubscriptions.remove(conversationId);
    if (subscription != null) {
      debugPrint('ChatWebSocketService: Unsubscribing from $conversationId');
      subscription();
    }
  }

  void subscribeToConversationList(int userId) {
    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint(
          'ChatWebSocketService: Cannot subscribe to list - not connected');
      return;
    }

    if (_conversationListSubscription != null) {
      debugPrint(
          'ChatWebSocketService: Already subscribed to conversation list');
      return;
    }

    debugPrint(
        'ChatWebSocketService: Subscribing to conversation list for user $userId');

    _conversationListSubscription = _stompClient!.subscribe(
      destination: '/topic/chat/conversations/$userId',
      callback: (frame) {
        debugPrint('ChatWebSocketService: Conversation list update received');
        onConversationUpdated?.call();
      },
    );
  }

  void unsubscribeFromConversationList() {
    if (_conversationListSubscription != null) {
      debugPrint('ChatWebSocketService: Unsubscribing from conversation list');
      _conversationListSubscription!();
      _conversationListSubscription = null;
    }
  }

  void sendMessage({
    required String conversationId,
    required String senderType,
    required String content,
  }) {
    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint('ChatWebSocketService: Cannot send message - not connected');
      return;
    }

    debugPrint(
        'ChatWebSocketService: Sending message to conversation $conversationId');

    _stompClient!.send(
      destination: '/app/chat/send',
      body:
          'conversationId=$conversationId&senderType=$senderType&content=${Uri.encodeComponent(content)}',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );
  }

  void markAsRead(String conversationId) {
    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint('ChatWebSocketService: Cannot mark as read - not connected');
      return;
    }

    debugPrint(
        'ChatWebSocketService: Marking messages as read in $conversationId');

    _stompClient!.send(
      destination: '/app/chat/read',
      body: 'conversationId=$conversationId',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );
  }

  void _clearSubscriptions() {
    for (final sub in _conversationSubscriptions.values) {
      sub();
    }
    _conversationSubscriptions.clear();
    _conversationListSubscription?.call();
    _conversationListSubscription = null;
  }

  void disconnect() {
    debugPrint('ChatWebSocketService: Disconnecting');
    _clearSubscriptions();
    _stompClient?.deactivate();
    _stompClient = null;
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final intVal = int.tryParse(value);
    if (intVal != null) return intVal;
    return value;
  }
}
