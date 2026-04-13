import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/app_constants.dart';

enum ShipperRealtimeEventType {
  connected,
  disconnected,
  orderCreated,
  orderAccepted,
  orderStatusChanged,
  profileUpdated,
  error,
}

class ShipperRealtimeEvent {
  final ShipperRealtimeEventType type;
  final Map<String, dynamic>? payload;
  final String? rawBody;
  final String? message;

  const ShipperRealtimeEvent({
    required this.type,
    this.payload,
    this.rawBody,
    this.message,
  });
}

class ShipperRealtimeStompService {
  StompClient? _client;
  final StreamController<ShipperRealtimeEvent> _eventsController =
      StreamController<ShipperRealtimeEvent>.broadcast();

  bool _isConnected = false;
  bool _isDisposed = false;
  bool get _canEmit => !_isDisposed && !_eventsController.isClosed;

  Stream<ShipperRealtimeEvent> get events => _eventsController.stream;
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
        onConnect: (frame) {
          _isConnected = true;
          _emitEvent(
            const ShipperRealtimeEvent(type: ShipperRealtimeEventType.connected),
          );

          _subscribe(
            destination: '/topic/orders/new',
            type: ShipperRealtimeEventType.orderCreated,
          );
          _subscribe(
            destination: '/topic/orders/accepted',
            type: ShipperRealtimeEventType.orderAccepted,
          );
          _subscribe(
            destination: '/topic/orders/status',
            type: ShipperRealtimeEventType.orderStatusChanged,
          );
          _subscribe(
            destination: '/user/queue/profile',
            type: ShipperRealtimeEventType.profileUpdated,
          );
        },
        onDisconnect: (_) {
          _isConnected = false;
          _emitEvent(
            const ShipperRealtimeEvent(
              type: ShipperRealtimeEventType.disconnected,
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
    required ShipperRealtimeEventType type,
  }) {
    _client?.subscribe(
      destination: destination,
      callback: (frame) {
        final payload = _parseJson(frame.body);
        _emitEvent(
          ShipperRealtimeEvent(type: type, payload: payload, rawBody: frame.body),
        );
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
    final wsPath = normalizedBasePath.isEmpty
        ? '/ws'
        : '$normalizedBasePath/ws';

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
      ShipperRealtimeEvent(
        type: ShipperRealtimeEventType.error,
        message: message,
      ),
    );
  }

  void _emitEvent(ShipperRealtimeEvent event) {
    if (!_canEmit) return;
    _eventsController.add(event);
  }
}
