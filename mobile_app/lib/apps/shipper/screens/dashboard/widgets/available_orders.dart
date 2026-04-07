import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/constants/shipper_strings.dart';
import 'package:grocery_shopping_app/apps/shipper/services/routing_service.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_dashboard_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/optimized_order_card.dart';
import '../../order_detail/order_detail_screen.dart';
import '../../delivery/delivery_flow_screen.dart';
import '../../delivery/order_map_screen.dart';

class AvailableOrdersList extends StatefulWidget {
  final List<ShipperOrder> orders;
  final Future<ShipperOrder?> Function(ShipperOrder order)? onAccept;

  const AvailableOrdersList({
    super.key,
    required this.orders,
    this.onAccept,
  });

  @override
  State<AvailableOrdersList> createState() => _AvailableOrdersListState();
}

class _AvailableOrdersListState extends State<AvailableOrdersList> {
  static const String _apiKey = 'c251cd70-5c14-49fe-a134-0ad33f0bf0ed';
  static final _routingService = GraphHopperRoutingService(apiKey: _apiKey);

  final Map<int, double> _distanceCache = {};
  final Map<String, LatLng> _geocodeCache = {};
  bool _isLoadingDistances = false;

  @override
  void initState() {
    super.initState();
    _calculateDistances();
  }

  @override
  void didUpdateWidget(AvailableOrdersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders.length != widget.orders.length ||
        oldWidget.orders.any((o) => !widget.orders.any((n) => n.id == o.id))) {
      _distanceCache.clear();
      _calculateDistances();
    }
  }

  Future<LatLng> _geocodeAddress(String address) async {
    if (address.isEmpty) {
      throw Exception('Address cannot be empty');
    }

    if (_geocodeCache.containsKey(address)) {
      return _geocodeCache[address]!;
    }

    try {
      final location = await _routingService.geocodeAddress(address);
      if (location == null) {
        throw Exception('Location not found for: $address');
      }
      _geocodeCache[address] = location;
      return location;
    } catch (e) {
      debugPrint('Geocoding failed for $address: $e');
      throw Exception('Geocoding failed for: $address - $e');
    }
  }

  Future<void> _calculateDistances() async {
    if (widget.orders.isEmpty) return;

    setState(() => _isLoadingDistances = true);

    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoadingDistances = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final shipperLoc = LatLng(position.latitude, position.longitude);

      for (final order in widget.orders) {
        if (_distanceCache.containsKey(order.id)) continue;

        try {
          final waypoints = <LatLng>[shipperLoc];
          final labels = <String>['Vị trí hiện tại'];

          if (order.stores.isNotEmpty) {
            for (final store in order.stores) {
              final storeLoc = await _geocodeAddress(store.address);
              waypoints.add(storeLoc);
              labels.add(store.name);
            }
          } else {
            final storeLoc = await _geocodeAddress(order.storeAddress);
            waypoints.add(storeLoc);
            labels.add(order.storeName);
          }

          final customerLoc = await _geocodeAddress(order.deliveryAddress);
          waypoints.add(customerLoc);
          labels.add('Khách hàng');

          final routeInfo = await _routingService.getMultiStopRoute(
            waypoints: waypoints,
            labels: labels,
            profile: 'car',
          );

          final distanceKm = routeInfo.totalDistanceKm;

          if (mounted) {
            setState(() => _distanceCache[order.id] = distanceKm);
          }
        } catch (e) {
          debugPrint('Distance calculation failed for order ${order.id}: $e');
          if (mounted) {
            setState(() => _distanceCache[order.id] = 0);
          }
        }
      }
    } catch (e) {
      debugPrint('Location permission or position error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDistances = false);
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ShipperDashboardBloc>().add(RefreshDashboardData());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 72,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  ShipperStrings.emptyOrdersTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ShipperTheme.textLightGreyColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  ShipperStrings.emptyOrdersSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShipperDashboardBloc>().add(RefreshDashboardData());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final order = widget.orders[index];
          final distance = _distanceCache[order.id] ?? order.distanceKm;

          return OptimizedOrderCard(
            order: order,
            distance: distance,
            isLoading: _isLoadingDistances,
            onStart: () async {
              if (order.status == OrderStatus.CONFIRMED) {
                // Parent (Dashboard) sẽ handle navigation sau khi accept
                await widget.onAccept?.call(order);
              } else if (order.status == OrderStatus.PICKING_UP ||
                  order.status == OrderStatus.DELIVERING) {
                // Mở map để tiếp tục giao hàng
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderMapScreen(
                      order: order,
                      showDeliveryRoute: order.status == OrderStatus.DELIVERING,
                    ),
                  ),
                );
              }
            },
            onDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              );
            },
            onMap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderMapScreen(
                    order: order,
                    showDeliveryRoute: order.status == OrderStatus.DELIVERING,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
