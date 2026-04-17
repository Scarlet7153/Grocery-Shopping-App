import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../auth/auth_session.dart';
import '../constants/app_constants.dart';
import '../models/chat_model.dart';

typedef MessageCallback = void Function(MessageModel message);
typedef ConversationUpdateCallback = void Function();

class ChatWebSocketService {
  static ChatWebSocketService? _instance;
  StompClient? _stompClient;
  final String _baseUrl;

  final Set<String> _pendingConversationIds = {};
  final Map<String, StompUnsubscribe> _conversationSubscriptions = {};
  bool _conversationListPending = false;
  StompUnsubscribe? _conversationListSubscription;

  final List<MessageCallback> _messageListeners = [];
  final List<ConversationUpdateCallback> _conversationUpdateListeners = [];
  final List<VoidCallback> _connectListeners = [];
  final List<VoidCallback> _disconnectListeners = [];
  final List<VoidCallback> _errorListeners = [];

  bool get isConnected => _stompClient?.connected ?? false;

  void addMessageListener(MessageCallback listener) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(MessageCallback listener) {
    _messageListeners.remove(listener);
  }

  void addConversationUpdateListener(ConversationUpdateCallback listener) {
    _conversationUpdateListeners.add(listener);
  }

  void removeConversationUpdateListener(ConversationUpdateCallback listener) {
    _conversationUpdateListeners.remove(listener);
  }

  void addConnectedListener(VoidCallback listener) {
    _connectListeners.add(listener);
  }

  void removeConnectedListener(VoidCallback listener) {
    _connectListeners.remove(listener);
  }

  void addDisconnectedListener(VoidCallback listener) {
    _disconnectListeners.add(listener);
  }

  void removeDisconnectedListener(VoidCallback listener) {
    _disconnectListeners.remove(listener);
  }

  void addErrorListener(VoidCallback listener) {
    _errorListeners.add(listener);
  }

  void removeErrorListener(VoidCallback listener) {
    _errorListeners.remove(listener);
  }

  ChatWebSocketService._internal(this._baseUrl);

  static ChatWebSocketService get instance {
    _instance ??= ChatWebSocketService._internal(_getWebSocketUrl());
    return _instance!;
  }

  static String _getWebSocketUrl() {
    final baseUrl = AppConstants.baseUrl;
    debugPrint('🌐 Base URL: $baseUrl');
    final uri = Uri.parse(baseUrl);
    // For SockJS endpoint we should use http/https (not ws/wss)
    final httpScheme = uri.scheme == 'https' ? 'https' : 'http';
    // Preserve any base path (e.g. '/api') and append '/ws'
    final pathPrefix = (uri.path.isEmpty || uri.path == '/') ? '' : uri.path;
    final wsPath = pathPrefix.endsWith('/') ? '${pathPrefix}ws' : '$pathPrefix/ws';
    final httpUri = uri.replace(
      scheme: httpScheme,
      path: wsPath,
      query: null,
      fragment: null,
    );
    debugPrint('📡 SockJS URL: $httpUri');
    return httpUri.toString();
  }

  Future<void> connect({String? authToken}) async {
    debugPrint('🔌 Attempting to connect WebSocket...');
    if (_stompClient != null && _stompClient!.connected) {
      debugPrint('ChatWebSocketService: Already connected');
      return;
    }

    debugPrint('ChatWebSocketService: Connecting to $_baseUrl');

    final token = await _getAuthToken(authToken);
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: _baseUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: (frame) {
          debugPrint('✅ WebSocket CONNECTED: $frame');
          _onConnect(frame);
        },
        onDisconnect: (frame) {
          debugPrint('❌ WebSocket DISCONNECTED: $frame');
          _onDisconnect(frame);
        },
        onWebSocketError: (error) {
          debugPrint('❌ WebSocket ERROR: $error');
          _onWebSocketError(error);
        },
        onStompError: (frame) {
          debugPrint('❌ STOMP ERROR: ${frame.body}');
          _onStompError(frame);
        },
        onUnhandledFrame: (frame) {
          debugPrint('⚠️ UNHANDLED FRAME: ${frame.command}');
          _onUnhandledFrame(frame);
        },
        reconnectDelay: const Duration(seconds: 2),
      ),
    );
    // Start the STOMP client
    try {
      _stompClient!.activate();
    } catch (e) {
      debugPrint('ChatWebSocketService: Failed to activate STOMP client: $e');
    }
  }

  Future<String?> _getAuthToken(String? explicitToken) async {
    if (explicitToken != null && explicitToken.isNotEmpty) {
      return explicitToken;
    }

    if (AuthSession.token != null && AuthSession.token!.isNotEmpty) {
      return AuthSession.token;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(AppConstants.accessTokenKey);
    if (storedToken != null && storedToken.isNotEmpty) {
      AuthSession.token = storedToken;
      return storedToken;
    }
    return null;
  }

  void _onConnect(StompFrame frame) {
    debugPrint('ChatWebSocketService: Connected');
    _restoreSubscriptions();
    for (final listener in _connectListeners) {
      listener();
    }
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('ChatWebSocketService: Disconnected');
    _clearSubscriptions();
    for (final listener in _disconnectListeners) {
      listener();
    }
  }

  void _onWebSocketError(dynamic error) {
    debugPrint('ChatWebSocketService: WebSocket error: $error');
    for (final listener in _errorListeners) {
      listener();
    }
  }

  void _onStompError(StompFrame frame) {
    debugPrint('ChatWebSocketService: STOMP error: ${frame.body}');
    for (final listener in _errorListeners) {
      listener();
    }
  }

  void _onUnhandledFrame(StompFrame frame) {
    debugPrint('ChatWebSocketService: Unhandled frame: ${frame.command}');
  }

  void subscribeToConversation(String conversationId) {
    _pendingConversationIds.add(conversationId);

    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint(
          'ChatWebSocketService: Queued subscription for conversation $conversationId');
      return;
    }

    if (_conversationSubscriptions.containsKey(conversationId)) {
      debugPrint('ChatWebSocketService: Already subscribed to $conversationId');
      return;
    }

    _subscribeToConversation(conversationId);
  }

  void _subscribeToConversation(String conversationId) {
    debugPrint(
        'ChatWebSocketService: Subscribing to conversation $conversationId');

    final subscription = _stompClient!.subscribe(
      destination: '/topic/chat/conversation/$conversationId',
      callback: (frame) {
        if (frame.body != null && frame.body!.isNotEmpty) {
          try {
            final jsonData = json.decode(frame.body!) as Map<String, dynamic>;
            final message = MessageModel.fromJson(jsonData);
            for (final listener in _messageListeners) {
              listener(message);
            }
          } catch (e) {
            debugPrint('ChatWebSocketService: Error parsing message: $e');
          }
        }
      },
    );

    _conversationSubscriptions[conversationId] = subscription;
  }

  void unsubscribeFromConversation(String conversationId) {
    _pendingConversationIds.remove(conversationId);
    final subscription = _conversationSubscriptions.remove(conversationId);
    if (subscription != null) {
      debugPrint('ChatWebSocketService: Unsubscribing from $conversationId');
      subscription();
    }
  }

  void subscribeToConversationList() {
    _conversationListPending = true;

    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint('ChatWebSocketService: Queued conversation list subscription');
      return;
    }

    if (_conversationListSubscription != null) {
      debugPrint(
          'ChatWebSocketService: Already subscribed to conversation list');
      return;
    }

    _subscribeToConversationList();
  }

  void _subscribeToConversationList() {
    debugPrint('ChatWebSocketService: Subscribing to conversation list');

    _conversationListSubscription = _stompClient!.subscribe(
      destination: '/user/queue/chat/conversations',
      callback: (frame) {
        debugPrint('ChatWebSocketService: Conversation list update received');
        for (final listener in _conversationUpdateListeners) {
          listener();
        }
      },
    );
  }

  void unsubscribeFromConversationList() {
    _conversationListPending = false;
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
      body: json.encode({
        'conversationId': conversationId,
        'senderType': senderType,
        'content': content,
      }),
      headers: {'Content-Type': 'application/json'},
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
      body: json.encode({'conversationId': conversationId}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  void _restoreSubscriptions() {
    if (_conversationListPending && _conversationListSubscription == null) {
      _subscribeToConversationList();
    }

    for (final conversationId in _pendingConversationIds) {
      if (!_conversationSubscriptions.containsKey(conversationId)) {
        _subscribeToConversation(conversationId);
      }
    }
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
}
