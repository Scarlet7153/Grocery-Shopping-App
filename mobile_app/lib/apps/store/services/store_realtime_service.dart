import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/app_constants.dart';

enum StoreRealtimeEventType {
  connected,
  disconnected,
  newOrder,
  orderAccepted,
  orderStatusChanged,
  notificationReceived,
  notificationUnreadCountUpdated,
  error,
}

class StoreRealtimeEvent {
  final StoreRealtimeEventType type;
  final Map<String, dynamic>? payload;
  final String? rawBody;
  final String? message;

  const StoreRealtimeEvent({
    required this.type,
    this.payload,
    this.rawBody,
    this.message,
  });
}

class StoreRealtimeService {
  StompClient? _client;
  final StreamController<StoreRealtimeEvent> _eventsController =
      StreamController<StoreRealtimeEvent>.broadcast();

  bool _isConnected = false;
  bool _isDisposed = false;
  bool get _canEmit => !_isDisposed && !_eventsController.isClosed;

  Stream<StoreRealtimeEvent> get events => _eventsController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isDisposed || _client != null) return;

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      developer.log('Store realtime: No token found', name: 'StoreRealtime');
      _emitError('Không tìm thấy token để kết nối STOMP');
      return;
    }

    developer.log('Store realtime: Connecting...', name: 'StoreRealtime');
    final authHeaders = {'Authorization': 'Bearer $token'};

    _client = StompClient(
      config: StompConfig.sockJS(
        url: _buildSockJsUrl(),
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 20),
        heartbeatOutgoing: const Duration(seconds: 20),
        stompConnectHeaders: authHeaders,
        webSocketConnectHeaders: authHeaders,
        onConnect: (frame) {
          developer.log('Store realtime: Connected!', name: 'StoreRealtime');
          _isConnected = true;
          _emitEvent(
              const StoreRealtimeEvent(type: StoreRealtimeEventType.connected));
          _subscribe(
              destination: '/topic/orders/new',
              type: StoreRealtimeEventType.newOrder);
          _subscribe(
              destination: '/topic/orders/accepted',
              type: StoreRealtimeEventType.orderAccepted);
          _subscribe(
              destination: '/topic/orders/status',
              type: StoreRealtimeEventType.orderStatusChanged);
          _subscribe(
            destination: '/user/queue/notifications',
            type: StoreRealtimeEventType.notificationReceived,
          );
          _subscribe(
            destination: '/user/queue/notifications/count',
            type: StoreRealtimeEventType.notificationUnreadCountUpdated,
          );
        },
        onDisconnect: (_) {
          _isConnected = false;
          _emitEvent(const StoreRealtimeEvent(
              type: StoreRealtimeEventType.disconnected));
        },
        onStompError: (frame) =>
            _emitError(frame.body ?? 'STOMP protocol error'),
        onWebSocketError: (dynamic error) => _emitError(error.toString()),
      ),
    );

    _client!.activate();
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    _isDisposed = true;
    _isConnected = false;
    _client?.deactivate();
    _client = null;
    if (!_eventsController.isClosed) _eventsController.close();
  }

  void _subscribe(
      {required String destination, required StoreRealtimeEventType type}) {
    developer.log('Store realtime: Subscribing to $destination',
        name: 'StoreRealtime');
    _client?.subscribe(
      destination: destination,
      callback: (frame) {
        developer.log(
            'Store realtime: Received message on $destination: ${frame.body?.substring(0, frame.body!.length > 100 ? 100 : frame.body!.length)}...',
            name: 'StoreRealtime');
        final payload = _parseJson(frame.body);
        _emitEvent(StoreRealtimeEvent(
            type: type, payload: payload, rawBody: frame.body));
      },
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  String _buildSockJsUrl() {
    final apiUri = Uri.parse(AppConstants.baseUrl);
    final httpScheme = apiUri.scheme == 'https' ? 'https' : 'http';
    final normalizedBasePath = apiUri.path.endsWith('/')
        ? apiUri.path.substring(0, apiUri.path.length - 1)
        : apiUri.path;
    final wsPath =
        normalizedBasePath.isEmpty ? '/ws' : '$normalizedBasePath/ws';
    return Uri(
            scheme: httpScheme,
            host: apiUri.host,
            port: apiUri.hasPort ? apiUri.port : null,
            path: wsPath)
        .toString();
  }

  Map<String, dynamic>? _parseJson(String? rawBody) {
    if (rawBody == null || rawBody.isEmpty) return null;
    try {
      final decoded = jsonDecode(rawBody);
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } catch (_) {
      return {'raw': rawBody};
    }
  }

  void _emitError(String message) => _emitEvent(
      StoreRealtimeEvent(type: StoreRealtimeEventType.error, message: message));

  void _emitEvent(StoreRealtimeEvent event) {
    if (!_canEmit) return;
    _eventsController.add(event);
  }
}
