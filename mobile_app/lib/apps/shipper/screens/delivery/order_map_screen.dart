import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/shipper_dashboard_bloc.dart';
import '../../models/shipper_order.dart';
import '../../repository/shipper_repository.dart';
import '../../repository/shipper_chat_api.dart';
import '../../services/routing_service.dart';
import '../../services/shipper_realtime_stomp_service.dart';
import '../../../../core/theme/shipper_theme.dart';
import '../../../../core/utils/app_localizations.dart';
import 'delivery_confirmation_screen.dart';
import '../order_detail/order_detail_screen.dart';
import '../chat/shipper_chat_screen.dart';

class OrderMapScreen extends StatefulWidget {
  final ShipperOrder order;
  final bool showDeliveryRoute;
  final String graphHopperApiKey;
  final VoidCallback? onStartDelivery;

  const OrderMapScreen({
    super.key,
    required this.order,
    this.showDeliveryRoute = false,
    this.graphHopperApiKey = 'c251cd70-5c14-49fe-a134-0ad33f0bf0ed',
    this.onStartDelivery,
  });

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late ShipperOrder _order;
  LatLng? _currentPosition;
  late LatLng _destination = const LatLng(10.762622, 106.660172);
  final List<LatLng> _storeLocations = [];
  final List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _isLoadingRoute = false;
  bool _isUpdatingStatus = false;
  bool _isDelivering = false; // Track delivery status
  bool _isNavigating = false; // Navigation mode - map rotates with heading
  double _heading = 0; // Current heading/direction
  String? _error;
  MultiStopRouteResult? _routeResult;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ShipperRealtimeEvent>? _realtimeSubscription;
  final GraphHopperRoutingService _routingService;
  final ShipperRealtimeStompService _realtimeService =
      ShipperRealtimeStompService();
  bool _isRealtimeSyncing = false;
  bool _showDirections = false;

  // Animation controllers for navigation transition
  AnimationController? _navAnimationController;
  Animation<double>? _zoomAnimation;
  Animation<double>? _rotationAnimation;

  _OrderMapScreenState()
      : _routingService = GraphHopperRoutingService(
          apiKey: 'c251cd70-5c14-49fe-a134-0ad33f0bf0ed',
        );

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    // Nếu order đã ở trạng thái DELIVERING hoặc DELIVERED, tự động bật chế độ giao hàng
    _isDelivering = _order.status == OrderStatus.DELIVERING ||
        _order.status == OrderStatus.DELIVERED;
    // Load lại trạng thái order mới nhất từ server
    _refreshOrderStatus();
    _initLocations();
    _startLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealtimeStreaming();
      }
    });
  }

  Future<void> _initRealtimeStreaming() async {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      if (!_isEventForCurrentOrder(event)) return;

      switch (event.type) {
        case ShipperRealtimeEventType.orderAccepted:
        case ShipperRealtimeEventType.orderStatusChanged:
          _refreshOrderStatusFromRealtime();
          break;
        case ShipperRealtimeEventType.error:
          debugPrint('OrderMap STOMP error: ${event.message}');
          break;
        case ShipperRealtimeEventType.connected:
        case ShipperRealtimeEventType.disconnected:
        case ShipperRealtimeEventType.notificationReceived:
        case ShipperRealtimeEventType.notificationUnreadCountUpdated:
        case ShipperRealtimeEventType.orderCreated:
        case ShipperRealtimeEventType.profileUpdated:
          break;
      }
    });

    await _realtimeService.connect();
  }

  bool _isEventForCurrentOrder(ShipperRealtimeEvent event) {
    final payload = event.payload;
    if (payload == null) return false;

    final rawOrderId = payload['orderId'] ?? payload['id'];
    final eventOrderId = rawOrderId is int
        ? rawOrderId
        : int.tryParse(rawOrderId?.toString() ?? '');

    return eventOrderId == _order.id;
  }

  Future<void> _refreshOrderStatusFromRealtime() async {
    if (!mounted || _isRealtimeSyncing) return;

    _isRealtimeSyncing = true;
    try {
      await _refreshOrderStatus();
    } finally {
      _isRealtimeSyncing = false;
    }
  }

  Future<void> _refreshOrderStatus() async {
    try {
      final repository = context.read<ShipperRepository>();
      final freshOrder = await repository.getOrderById(_order.id);
      if (freshOrder != null && mounted) {
        setState(() {
          _order = freshOrder;
          // Cập nhật lại _isDelivering dựa trên status mới
          _isDelivering = _order.status == OrderStatus.DELIVERING ||
              _order.status == OrderStatus.DELIVERED;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing order status: $e');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    _navAnimationController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocations() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Vui lòng cấp quyền truy cập vị trí';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location timeout - please check GPS');
        },
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      await _setupMarkersAsync();
      setState(() {});
      await _fetchMultiStopRoute();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Không thể xác định vị trí: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMultiStopRoute() async {
    if (_currentPosition == null || _storeLocations.isEmpty) return;

    setState(() => _isLoadingRoute = true);

    try {
      // Nếu đang ở PICKING_UP và chưa ấn "Bắt đầu giao hàng",
      // chỉ hiển thị route đến store (không đến khách hàng)
      final isGoingToStoreOnly = _order.status == OrderStatus.PICKING_UP &&
          !_isDelivering &&
          !widget.showDeliveryRoute;

      final waypoints = isGoingToStoreOnly
          ? <LatLng>[_currentPosition!, ..._storeLocations]
          : <LatLng>[_currentPosition!, ..._storeLocations, _destination];

      final labels = isGoingToStoreOnly
          ? <String>['Vị trí hiện tại', ..._storeLabels]
          : <String>['Vị trí hiện tại', ..._storeLabels, 'Khách hàng'];

      final result = await _routingService.getMultiStopRoute(
        waypoints: waypoints,
        labels: labels,
        profile: 'car',
      );

      _routePoints.clear();
      _routePoints.addAll(result.points);
      _routeResult = result;
    } catch (e) {
      // Route calculation failed
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  List<String> get _storeLabels {
    final order = widget.order;
    if (order.stores.isNotEmpty) {
      return order.stores.map((s) => s.name).toList();
    }
    return [order.storeName];
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update more frequently for navigation
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _heading = position.heading; // Get heading direction
        });
        _updateCurrentMarker();

        // Auto-rotate map when in navigation mode
        if (_isNavigating && _currentPosition != null) {
          _updateNavigationCamera();
        }
      }
    });
  }

  void _updateNavigationCamera() {
    if (_currentPosition == null) return;

    // Rotate map to match heading (subtract 90 or adjust based on your marker orientation)
    // Heading 0 = North, 90 = East, 180 = South, 270 = West
    // We want the map to rotate so the top is always the direction of travel
    final rotation =
        360 - _heading; // Invert because flutter_map rotates counter-clockwise

    _mapController.move(_currentPosition!, _mapController.camera.zoom);
    _mapController.rotate(rotation);
  }

  void _toggleNavigationMode() {
    setState(() {
      _isNavigating = !_isNavigating;
    });

    if (_isNavigating && _currentPosition != null) {
      // Enter navigation mode - center on current position and start rotating
      _mapController.move(_currentPosition!, 18); // Zoom in closer
      _updateNavigationCamera();
    } else {
      // Exit navigation mode - reset rotation
      _mapController.rotate(0);
    }
  }

  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _setupMarkersAsync() async {
    _storeLocations.clear();
    final order = widget.order;
    bool hasGeocodingError = false;

    if (order.stores.isNotEmpty) {
      for (final store in order.stores) {
        try {
          final location = await _geocodeAddressAsync(store.address);
          _storeLocations.add(location);
        } catch (e) {
          debugPrint('Geocoding failed for store ${store.name}: $e');
          hasGeocodingError = true;
          _storeLocations.add(_parseAddress(store.address));
        }
      }
    } else {
      try {
        final location = await _geocodeAddressAsync(order.storeAddress);
        _storeLocations.add(location);
      } catch (e) {
        debugPrint('Geocoding failed for store address: $e');
        hasGeocodingError = true;
        _storeLocations.add(_parseAddress(order.storeAddress));
      }
    }
    try {
      _destination = await _geocodeAddressAsync(order.deliveryAddress);
    } catch (e) {
      debugPrint('Geocoding failed for delivery address: $e');
      hasGeocodingError = true;
      _destination = _parseAddress(order.deliveryAddress);
    }

    if (hasGeocodingError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Một số địa chỉ không geocode được, dùng vị trí ước lượng',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateCurrentMarker() {
    if (_currentPosition == null || !mounted) return;
    setState(() {});
  }

  Future<LatLng> _geocodeAddressAsync(String address) async {
    if (address.isEmpty) {
      throw Exception('Address cannot be empty');
    }
    try {
      final location = await _routingService.geocodeAddress(address);
      if (location == null) {
        throw Exception('Location not found for: $address');
      }
      return location;
    } catch (e) {
      debugPrint('Geocoding failed for $address: $e');
      throw Exception('Geocoding failed for: $address - $e');
    }
  }

  LatLng _parseAddress(String address) {
    final hash = address.hashCode.abs();
    return LatLng(
      10.762622 + (hash % 100) * 0.001,
      106.660172 + (hash % 50) * 0.001,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Bản đồ giao hàng'),
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoadingRoute)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: Icon(_showDirections ? Icons.map : Icons.directions),
            onPressed: () => setState(() => _showDirections = !_showDirections),
            tooltip: _showDirections ? 'Ẩn chỉ dẫn' : 'Hiển thị chỉ dẫn',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition ??
                            (_storeLocations.isNotEmpty
                                ? _storeLocations.first
                                : _destination),
                        initialZoom: 14,
                        minZoom: 10,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.grocery.shopping_app',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: const Color(0xFF4285F4),
                                strokeWidth: 5,
                              ),
                            ],
                          ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    if (_showDirections) _buildDirectionsPanel(),
                    _buildLocationInfoPanel(l),

                    // Navigation mode toggle button
                    if (_isDelivering)
                      Positioned(
                        right: 16,
                        bottom: 320, // Above the location info panel
                        child: FloatingActionButton.small(
                          heroTag: 'navigation_toggle',
                          onPressed: _toggleNavigationMode,
                          backgroundColor: _isNavigating
                              ? ShipperTheme.primaryColor
                              : Colors.white,
                          foregroundColor:
                              _isNavigating ? Colors.white : Colors.black87,
                          child: Icon(
                            _isNavigating
                                ? Icons.navigation
                                : Icons.navigation_outlined,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 40,
          height: 40,
          child: _buildCurrentLocationMarker(),
        ),
      );
    }

    for (int i = 0; i < _storeLocations.length; i++) {
      final storeName = i < widget.order.stores.length
          ? widget.order.stores[i].name
          : widget.order.storeName;
      markers.add(
        Marker(
          point: _storeLocations[i],
          width: 40,
          height: 40,
          child: _buildLocationMarker(Icons.store, Colors.purple, storeName),
        ),
      );
    }

    markers.add(
      Marker(
        point: _destination,
        width: 40,
        height: 40,
        child: _buildLocationMarker(
          Icons.location_on,
          Colors.green,
          'Khách hàng',
        ),
      ),
    );

    return markers;
  }

  Widget _buildCurrentLocationMarker() {
    return Transform.rotate(
      angle: _isNavigating ? (_heading * 3.14159 / 180) : 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLocationMarker(IconData icon, Color color, String label) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 5),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _initLocations();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoPanel(AppLocalizations l) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isDelivering) ...[
              // ===== BEFORE DELIVERY - Route info =====
              if (_routeResult != null && _routeResult!.segments.isNotEmpty)
                ..._buildStoreSteps()
              else
                _buildLocationStep(
                  icon: Icons.store,
                  title: widget.order.storeName,
                  subtitle: widget.order.storeAddress,
                  color: Colors.purple,
                  isActive: !widget.showDeliveryRoute,
                  distance: null,
                  duration: null,
                ),
              const SizedBox(height: 12),

              // Action buttons row
              if (_routeResult != null && _routeResult!.totalDistanceKm > 0)
                Row(
                  children: [
                    // Chi tiết đơn hàng button (secondary)
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailScreen(order: _order),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long, size: 20),
                          label: const Text(
                            'Chi tiết đơn',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ShipperTheme.primaryColor,
                            side: const BorderSide(
                                color: ShipperTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Start delivery button (primary)
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isUpdatingStatus ? null : _startDelivery,
                          icon: _isUpdatingStatus
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            _isUpdatingStatus ? 'Đang cập nhật...' : 'Bắt đầu',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ShipperTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ] else ...[
              // ===== DURING DELIVERY - Customer info + Actions =====
              // Status badge (16px text)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _order.status == OrderStatus.PICKING_UP
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_order.status == OrderStatus.DELIVERED)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      )
                    else
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _order.status == OrderStatus.PICKING_UP
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _order.status == OrderStatus.PICKING_UP
                          ? 'Xác nhận nhận hàng'
                          : _order.status == OrderStatus.DELIVERED
                              ? 'Đã giao thành công'
                              : 'Đang giao hàng',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _order.status == OrderStatus.PICKING_UP
                                ? Colors.orange
                                : Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer info card (16px+ text)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ShipperTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer name - LARGE (18px)
                    Text(
                      _order.customerName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Phone (clickable)
                    InkWell(
                      onTap: () async {
                        try {
                          await launchUrl(
                            Uri(
                              scheme: 'tel',
                              path: _order.customerPhone,
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không thể gọi')),
                            );
                          }
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            color: ShipperTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _order.customerPhone,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: ShipperTheme.primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Address (16px)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _order.deliveryAddress,
                            style: Theme.of(context).textTheme.bodyLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ===== ACTION BUTTONS - Thumb zone =====
              Row(
                children: [
                  // Call button
                  SizedBox(
                    height: 48,
                    width: 80,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await launchUrl(
                            Uri(
                              scheme: 'tel',
                              path: _order.customerPhone,
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không thể gọi')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text(
                        'Gọi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ShipperTheme.secondaryColor,
                        side: const BorderSide(
                          color: ShipperTheme.secondaryColor,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Chat button
                  SizedBox(
                    height: 48,
                    width: 100,
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text(
                        'Nhắn tin',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Confirm button based on status
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _order.status == OrderStatus.PICKING_UP
                            ? (_isUpdatingStatus
                                ? null
                                : _confirmReceivedFromStore)
                            : _order.status == OrderStatus.DELIVERING
                                ? () async {
                                    final updatedOrder =
                                        await Navigator.push<ShipperOrder>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DeliveryConfirmationScreen(
                                          order: _order,
                                        ),
                                      ),
                                    );

                                    if (!mounted || updatedOrder == null) {
                                      return;
                                    }

                                    context.read<ShipperDashboardBloc>().add(
                                          RefreshDashboardData(),
                                        );

                                    if (!mounted) return;

                                    Navigator.of(context).pop(true);
                                  }
                                : null,
                        icon: _isUpdatingStatus
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle, size: 20),
                        label: Text(
                          _order.status == OrderStatus.PICKING_UP
                              ? (_isUpdatingStatus
                                  ? 'Đang xác nhận...'
                                  : 'Xác nhận nhận hàng')
                              : _order.status == OrderStatus.DELIVERING
                                  ? 'Xác nhận'
                                  : 'Đơn đã hoàn tất',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _order.status == OrderStatus.DELIVERED
                                  ? Colors.green
                                  : ShipperTheme.successColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _order.status == OrderStatus.DELIVERED
                                  ? Colors.green
                                  : ShipperTheme.successColor,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isActive,
    double? distance,
    int? duration,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (distance != null && duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${distance.toStringAsFixed(1)} km • $duration ph',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isActive)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
      ],
    );
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    }
  }

  Future<void> _startDelivery() async {
    // Chỉ đổi UI, KHÔNG gọi API đổi status
    setState(() {
      _isDelivering = true;
      _isNavigating = true;
    });

    // Re-calculate route to customer (now include destination)
    await _fetchMultiStopRoute();

    // Animation transition
    if (_currentPosition != null) {
      _animateToNavigationMode();
    }

    // Callback cho parent widget nếu có
    if (widget.onStartDelivery != null) {
      widget.onStartDelivery!();
    }
  }

  Future<void> _confirmReceivedFromStore() async {
    // Gọi API để đổi status từ PICKING_UP sang DELIVERING
    setState(() => _isUpdatingStatus = true);

    try {
      final repository = context.read<ShipperRepository>();
      final updated = await repository.updateOrderStatus(
        _order.id,
        'DELIVERING',
      );

      if (!mounted) return;

      if (updated != null) {
        setState(() {
          _order = updated;
        });

        // Refresh dashboard data
        context.read<ShipperDashboardBloc>().add(RefreshDashboardData());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận nhận hàng từ cửa hàng')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _openChat() async {
    try {
      final chatApi = ShipperChatApi();
      final conv =
          await chatApi.createOrGetConversation(_order.id, _order.customerId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShipperChatScreen(
            conversationId: conv.id,
            customerName: _order.customerName,
            orderId: _order.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Không thể mở chat'),
        ),
      );
    }
  }

  void _animateToNavigationMode() {
    if (_currentPosition == null) return;

    // Get current camera state
    final currentZoom = _mapController.camera.zoom;
    final currentRotation = _mapController.camera.rotation;
    const targetZoom = 18.0;

    // Calculate shortest rotation angle (avoid spinning multiple circles)
    var targetRotation =
        -_heading; // Negative because flutter_map rotates counter-clockwise
    var rotationDiff = targetRotation - currentRotation;

    // Normalize to -180 to 180 range (shortest path)
    while (rotationDiff > 180) {
      rotationDiff -= 360;
    }
    while (rotationDiff < -180) {
      rotationDiff += 360;
    }

    final endRotation = currentRotation + rotationDiff;

    // Create animation controller
    _navAnimationController?.dispose();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Zoom animation (ease in out)
    _zoomAnimation = Tween<double>(begin: currentZoom, end: targetZoom).animate(
      CurvedAnimation(
        parent: _navAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Rotation animation (ease in out) - shortest path
    _rotationAnimation =
        Tween<double>(begin: currentRotation, end: endRotation).animate(
      CurvedAnimation(
        parent: _navAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Listen to animation and update map
    _navAnimationController!.addListener(() {
      if (!mounted || _currentPosition == null) return;

      final zoom = _zoomAnimation!.value;
      final rotation = _rotationAnimation!.value;

      _mapController.move(_currentPosition!, zoom);
      _mapController.rotate(rotation);
    });

    // Start animation
    _navAnimationController!.forward();
  }

  // ignore: unused_element
  void _showOrderDetailsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: ShipperTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chi tiết đơn hàng #${_order.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Store info
                    _buildDialogSection('Cửa hàng', [
                      _buildDialogItem(Icons.store, _order.storeName),
                      _buildDialogItem(Icons.location_on, _order.storeAddress),
                    ]),
                    const SizedBox(height: 16),
                    // Customer info
                    _buildDialogSection('Khách hàng', [
                      _buildDialogItem(Icons.person, _order.customerName),
                      _buildDialogItem(Icons.phone, _order.customerPhone),
                      _buildDialogItem(
                        Icons.location_on,
                        _order.deliveryAddress,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Items (nếu có)
                    if (_order.items.isNotEmpty)
                      _buildDialogSection(
                        'Sản phẩm (${_order.items.length})',
                        _order.items
                            .map(
                              (item) => _buildDialogItem(
                                Icons.shopping_bag,
                                '${item.productName} x${item.quantity}',
                                trailing:
                                    '${item.subtotal.toStringAsFixed(0)}₫',
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_order.grandTotal.toStringAsFixed(0)}₫',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ShipperTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDialogItem(IconData icon, String text, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildStoreSteps() {
    if (_routeResult == null) return [];
    final widgets = <Widget>[];
    final order = widget.order;

    for (int i = 0; i < _routeResult!.segments.length; i++) {
      final segment = _routeResult!.segments[i];
      final isLastStore = i == _routeResult!.segments.length - 1 ||
          segment.label.contains('Khách');

      String subtitle = '';
      if (isLastStore) {
        subtitle = order.deliveryAddress;
      } else if (order.stores.isNotEmpty && i < order.stores.length) {
        subtitle = order.stores[i].address;
      } else {
        subtitle = order.storeAddress;
      }

      widgets.add(
        _buildLocationStep(
          icon: isLastStore ? Icons.location_on : Icons.store,
          title: segment.label,
          subtitle: subtitle,
          color: isLastStore ? Colors.green : Colors.purple,
          isActive: true,
          distance: segment.distanceKm,
          duration: segment.durationMinutes,
        ),
      );
      if (i < _routeResult!.segments.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildDirectionsPanel() {
    final segments = _routeResult?.segments ?? [];
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 300,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: ShipperTheme.primaryColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Tổng quãng đường',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_routeResult != null)
                    Text(
                      '${_routeResult!.totalDistanceKm.toStringAsFixed(1)} km • ${_routeResult!.totalDurationMinutes} ph',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: segments.length,
                itemBuilder: (context, index) {
                  final seg = segments[index];
                  return _buildSegmentItem(seg, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentItem(RouteSegment seg, int index) {
    final segments = _routeResult?.segments ?? [];
    final isLast = index == segments.length - 1;
    final distanceText = seg.distanceKm >= 1
        ? '${seg.distanceKm.toStringAsFixed(1)} km'
        : '${(seg.distance * 1000).toInt()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isLast ? Colors.green : Colors.purple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isLast ? Icons.location_on : Icons.store,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.directions, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seg.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (!isLast)
                  Text(
                    '→ ${segments[index + 1].label}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),
          Text(
            distanceText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
