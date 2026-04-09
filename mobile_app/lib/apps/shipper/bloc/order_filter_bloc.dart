import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:grocery_shopping_app/apps/shipper/models/order_filter.dart';

part 'order_filter_event.dart';
part 'order_filter_state.dart';

class OrderFilterBloc extends Bloc<OrderFilterEvent, OrderFilterState> {
  static const String FILTER_STORAGE_KEY = 'shipper_order_filter';

  OrderFilterBloc() : super(const OrderFilterInitial()) {
    on<LoadOrderFilter>(_onLoadOrderFilter);
    on<UpdateOrderFilter>(_onUpdateOrderFilter);
    on<ResetOrderFilter>(_onResetOrderFilter);
    on<SaveOrderFilter>(_onSaveOrderFilter);
    on<UpdateMaxDistance>(_onUpdateMaxDistance);
    on<UpdateMinEarning>(_onUpdateMinEarning);
    on<ToggleAvoidPickup>(_onToggleAvoidPickup);
    on<UpdateFavoriteStores>(_onUpdateFavoriteStores);
    on<UpdateMaxItems>(_onUpdateMaxItems);
  }

  /// Load filter từ SharedPreferences
  Future<void> _onLoadOrderFilter(
    LoadOrderFilter event,
    Emitter<OrderFilterState> emit,
  ) async {
    emit(const OrderFilterLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString(FILTER_STORAGE_KEY);

      late OrderFilter filter;
      if (filterJson != null) {
        // Load từ saved preference
        final Map<String, dynamic> decoded = jsonDecode(filterJson);
        filter = OrderFilter.fromJson(decoded);
      } else {
        // Load default filter
        filter = OrderFilter.defaultFilter();
      }

      emit(OrderFilterLoaded(filter));
    } catch (e) {
      emit(OrderFilterError('Không thể load filter: ${e.toString()}'));
    }
  }

  /// Update filter (cập nhật toàn bộ)
  Future<void> _onUpdateOrderFilter(
    UpdateOrderFilter event,
    Emitter<OrderFilterState> emit,
  ) async {
    emit(OrderFilterLoaded(event.filter));
  }

  /// Reset filter về default
  Future<void> _onResetOrderFilter(
    ResetOrderFilter event,
    Emitter<OrderFilterState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(FILTER_STORAGE_KEY);
      emit(OrderFilterLoaded(OrderFilter.defaultFilter()));
    } catch (e) {
      emit(OrderFilterError('Không thể reset filter: ${e.toString()}'));
    }
  }

  /// Save filter vào SharedPreferences
  Future<void> _onSaveOrderFilter(
    SaveOrderFilter event,
    Emitter<OrderFilterState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = jsonEncode(event.filter.toJson());
      await prefs.setString(FILTER_STORAGE_KEY, filterJson);
      emit(OrderFilterSaved(event.filter));
      // Sau đó emit Loaded state
      emit(OrderFilterLoaded(event.filter));
    } catch (e) {
      emit(OrderFilterError('Không thể save filter: ${e.toString()}'));
    }
  }

  /// Cập nhật max distance
  Future<void> _onUpdateMaxDistance(
    UpdateMaxDistance event,
    Emitter<OrderFilterState> emit,
  ) async {
    if (state is OrderFilterLoaded) {
      final currentFilter = (state as OrderFilterLoaded).filter;
      final newFilter = currentFilter.copyWith(maxDistance: event.distance);
      emit(OrderFilterLoaded(newFilter));
    }
  }

  /// Cập nhật minimum earning
  Future<void> _onUpdateMinEarning(
    UpdateMinEarning event,
    Emitter<OrderFilterState> emit,
  ) async {
    if (state is OrderFilterLoaded) {
      final currentFilter = (state as OrderFilterLoaded).filter;
      final newFilter = currentFilter.copyWith(minEarning: event.earning);
      emit(OrderFilterLoaded(newFilter));
    }
  }

  /// Toggle avoid pickup
  Future<void> _onToggleAvoidPickup(
    ToggleAvoidPickup event,
    Emitter<OrderFilterState> emit,
  ) async {
    if (state is OrderFilterLoaded) {
      final currentFilter = (state as OrderFilterLoaded).filter;
      final newFilter = currentFilter.copyWith(avoidPickup: event.avoid);
      emit(OrderFilterLoaded(newFilter));
    }
  }

  /// Cập nhật favorite stores
  Future<void> _onUpdateFavoriteStores(
    UpdateFavoriteStores event,
    Emitter<OrderFilterState> emit,
  ) async {
    if (state is OrderFilterLoaded) {
      final currentFilter = (state as OrderFilterLoaded).filter;
      final newFilter = currentFilter.copyWith(storeIds: event.storeIds);
      emit(OrderFilterLoaded(newFilter));
    }
  }

  /// Cập nhật max items
  Future<void> _onUpdateMaxItems(
    UpdateMaxItems event,
    Emitter<OrderFilterState> emit,
  ) async {
    if (state is OrderFilterLoaded) {
      final currentFilter = (state as OrderFilterLoaded).filter;
      final newFilter = currentFilter.copyWith(maxItems: event.maxItems);
      emit(OrderFilterLoaded(newFilter));
    }
  }
}
