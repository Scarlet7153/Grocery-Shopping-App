import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_dashboard_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/repository/shipper_repository.dart';

class _FakeRepo implements ShipperRepository {
  @override
  Future<Map<String, dynamic>> fetchDashboardData() async {
    return {
      'isOnline': false,
      'earnings': 0.0,
      'availableOrders': [],
      'deliveries': [],
      'completedCount': 0,
      'acceptanceRate': 0.0,
    };
  }

  @override
  Future<List<ShipperOrder>> getAvailableOrders() async {
    return [];
  }

  @override
  Future<List<ShipperOrder>> getMyDeliveries() async {
    return [];
  }

  @override
  Future<ShipperOrder?> assignOrder(int orderId) async {
    return null;
  }

  @override
  Future<ShipperOrder?> updateOrderStatus(int orderId, String newStatus,
          {String? podImageUrl}) async {
    return null;
  }

  @override
  Future<bool> login({required String phone, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> register(Map<String, dynamic> info) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    // no-op for fake
    return;
  }
}

void main() {
  group('ShipperDashboardBloc', () {
    late ShipperDashboardBloc bloc;

    setUp(() {
      bloc = ShipperDashboardBloc(repository: _FakeRepo());
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is initial', () {
      expect(bloc.state.status, DashboardStatus.initial);
    });

    blocTest<ShipperDashboardBloc, ShipperDashboardState>(
      'emits loading then loaded when data is fetched',
      build: () => bloc,
      act: (b) => b.add(LoadDashboardData()),
      expect: () => [
        bloc.state.copyWith(status: DashboardStatus.loading),
        bloc.state.copyWith(
          status: DashboardStatus.loaded,
          isOnline: false,
          earnings: 0.0,
          availableOrders: [],
          deliveries: [],
          completedCount: 0,
          acceptanceRate: 0.0,
        ),
      ],
    );

    blocTest<ShipperDashboardBloc, ShipperDashboardState>(
      'toggle online flips isOnline flag',
      build: () => bloc,
      act: (b) => b.add(ToggleOnlineStatus()),
      expect: () => [bloc.state.copyWith(isOnline: !bloc.state.isOnline)],
    );
  });
}