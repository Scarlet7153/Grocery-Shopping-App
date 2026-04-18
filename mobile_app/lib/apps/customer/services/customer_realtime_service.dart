import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_constants.dart';

enum CustomerRealtimeEventType {
  connected,
  disconnected,
  orderCreated,
  orderStatusChanged,
  notificationReceived,
  notificationUnreadCountUpdated,
  error,
}

class CustomerRealtimeEvent {
  final CustomerRealtimeEventType type;
  final Map<String, dynamic>? payload;
  final String? rawBody;
  final String? message;

  const CustomerRealtimeEvent({
    required this.type,
    this.payload,
    this.rawBody,
    this.message,
  });
}

class CustomerRealtimeService {
  static const String _customerTokenKey = 'customer_auth_token';

  StompClient? _client;
  final StreamController<CustomerRealtimeEvent> _eventsController =
      StreamController<CustomerRealtimeEvent>.broadcast();

  bool _isConnected = false;
  bool _isDisposed = false;
  bool get _canEmit => !_isDisposed && !_eventsController.isClosed;

  Stream<CustomerRealtimeEvent> get events => _eventsController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isDisposed || _client != null) return;

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _emitError('Không tìm thấy token để kết nối STOMP');
      return;
    }

    final authHeaders = {'Authorization': 'Bearer $token'};

    _client = StompClient(
      config: StompConfig.sockJS(
        url: _buildSockJsUrl(),
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 20),
        heartbeatOutgoing: const Duration(seconds: 20),
        stompConnectHeaders: authHeaders,
        webSocketConnectHeaders: authHeaders,
        onConnect: (_) {
          _isConnected = true;
          _emitEvent(
            const CustomerRealtimeEvent(type: CustomerRealtimeEventType.connected),
          );

          _subscribe(
            destination: '/topic/orders/new',
            type: CustomerRealtimeEventType.orderCreated,
          );
          _subscribe(
            destination: '/topic/orders/status',
            type: CustomerRealtimeEventType.orderStatusChanged,
          );
          _subscribe(
            destination: '/user/queue/orders',
            type: CustomerRealtimeEventType.orderStatusChanged,
          );
          _subscribe(
            destination: '/user/queue/notifications',
            type: CustomerRealtimeEventType.notificationReceived,
          );
          _subscribe(
            destination: '/user/queue/notifications/count',
            type: CustomerRealtimeEventType.notificationUnreadCountUpdated,
          );
        },
        onDisconnect: (_) {
          _isConnected = false;
          _emitEvent(
            const CustomerRealtimeEvent(
              type: CustomerRealtimeEventType.disconnected,
            ),
          );
        },
        onStompError: (frame) {
          _emitError(frame.body ?? 'STOMP protocol error');
        },
        onWebSocketError: (dynamic error) {
          _emitError(error.toString());
        },
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

    final client = _client;
    _client = null;
    client?.deactivate();

    if (!_eventsController.isClosed) {
      _eventsController.close();
    }
  }

  void _subscribe({
    required String destination,
    required CustomerRealtimeEventType type,
  }) {
    _client?.subscribe(
      destination: destination,
      callback: (frame) {
        final payload = _parseJson(frame.body);
        _emitEvent(
          CustomerRealtimeEvent(type: type, payload: payload, rawBody: frame.body),
        );
      },
    );
  }

  Future<String?> _getToken() async {
    final inMemoryToken = AuthSession.token;
    if (inMemoryToken != null && inMemoryToken.isNotEmpty) {
      return inMemoryToken;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerTokenKey) ??
        prefs.getString(AppConstants.accessTokenKey);
  }

  String _buildSockJsUrl() {
    final apiUri = Uri.parse(AppConstants.baseUrl);
    final httpScheme = apiUri.scheme == 'https' ? 'https' : 'http';
    final normalizedBasePath = apiUri.path.endsWith('/')
        ? apiUri.path.substring(0, apiUri.path.length - 1)
        : apiUri.path;
    final wsPath = normalizedBasePath.isEmpty ? '/ws' : '$normalizedBasePath/ws';

    return Uri(
      scheme: httpScheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: wsPath,
    ).toString();
  }

  Map<String, dynamic>? _parseJson(String? rawBody) {
    if (rawBody == null || rawBody.isEmpty) return null;

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      return {'raw': rawBody};
    }
  }

  void _emitError(String message) {
    _emitEvent(
      CustomerRealtimeEvent(
        type: CustomerRealtimeEventType.error,
        message: message,
      ),
    );
  }

  void _emitEvent(CustomerRealtimeEvent event) {
    if (!_canEmit) return;
    _eventsController.add(event);
  }
}
