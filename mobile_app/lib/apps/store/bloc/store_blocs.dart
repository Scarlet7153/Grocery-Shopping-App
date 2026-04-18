import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/store/data/store_service.dart';
import '../../../features/store/data/store_model.dart';
import '../../../features/orders/data/order_service.dart';
import '../../../features/orders/data/order_model.dart';
import '../../../features/products/data/product_service.dart';
import '../../../features/products/data/product_model.dart';
import '../../../features/products/data/category_service.dart';
import '../../../features/products/data/category_model.dart';
import '../../../features/products/data/unit_service.dart';
import '../../../features/products/data/unit_model.dart';
import '../../../features/review/data/review_service.dart';
import '../../../features/review/data/review_model.dart';
import '../../../features/notification/bloc/notification_bloc.dart';
import '../../../features/notification/data/notification_model.dart';
import '../services/store_realtime_service.dart';

// ============ DASHBOARD BLOC ============
abstract class StoreDashboardEvent {}

class LoadStoreDashboard extends StoreDashboardEvent {}

class ToggleStoreStatus extends StoreDashboardEvent {
  final int storeId;
  ToggleStoreStatus(this.storeId);
}

class UpdateStoreProfileEvent extends StoreDashboardEvent {
  final int storeId;
  final String storeName;
  final String address;
  final String? imageUrl;
  UpdateStoreProfileEvent(
      {required this.storeId,
      required this.storeName,
      required this.address,
      this.imageUrl});
}

abstract class StoreDashboardState {}

class StoreDashboardInitial extends StoreDashboardState {}

class StoreDashboardLoading extends StoreDashboardState {}

class StoreDashboardLoaded extends StoreDashboardState {
  final StoreModel store;
  final bool isStatusUpdating;

  StoreDashboardLoaded(this.store, {this.isStatusUpdating = false});
}

class StoreDashboardError extends StoreDashboardState {
  final String message;
  StoreDashboardError(this.message);
}

class StoreDashboardBloc
    extends Bloc<StoreDashboardEvent, StoreDashboardState> {
  final StoreService _storeService;
  StoreDashboardBloc(this._storeService) : super(StoreDashboardInitial()) {
    on<LoadStoreDashboard>(_onLoad);
    on<ToggleStoreStatus>(_onToggleStatus);
    on<UpdateStoreProfileEvent>(_onUpdateProfile);
  }
  Future<void> _onLoad(
      LoadStoreDashboard event, Emitter<StoreDashboardState> emit) async {
    emit(StoreDashboardLoading());
    try {
      final store = await _storeService.getStoreInfo();
      emit(store != null
          ? StoreDashboardLoaded(store)
          : StoreDashboardError('Không tải được thông tin cửa hàng'));
    } catch (e) {
      emit(StoreDashboardError(e.toString()));
    }
  }

  Future<void> _onToggleStatus(
      ToggleStoreStatus event, Emitter<StoreDashboardState> emit) async {
    final current = state;
    if (current is! StoreDashboardLoaded) return;

    final previousStore = current.store;
    final toggledStore = previousStore.copyWith(
      isOpen: !(previousStore.isOpen ?? false),
    );

    // Optimistic update to avoid full-screen loading flicker.
    emit(StoreDashboardLoaded(toggledStore, isStatusUpdating: true));

    try {
      await _storeService.toggleStoreStatus(event.storeId);
      emit(StoreDashboardLoaded(toggledStore));
    } catch (e) {
      // Roll back when request fails while keeping current screen stable.
      emit(StoreDashboardLoaded(previousStore));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateStoreProfileEvent event, Emitter<StoreDashboardState> emit) async {
    try {
      await _storeService.updateStoreProfile(
          event.storeId,
          UpdateStoreProfileRequest(
              storeName: event.storeName,
              address: event.address,
              imageUrl: event.imageUrl));
      add(LoadStoreDashboard());
    } catch (e) {
      emit(StoreDashboardError(e.toString()));
    }
  }
}

// ============ ORDERS BLOC ============
abstract class StoreOrdersEvent {}

class LoadStoreOrders extends StoreOrdersEvent {}

class UpdateOrderStatus extends StoreOrdersEvent {
  final int orderId;
  final String status;
  UpdateOrderStatus(this.orderId, this.status);
}

class _RealtimeOrdersChanged extends StoreOrdersEvent {}

abstract class StoreOrdersState {}

class StoreOrdersInitial extends StoreOrdersState {}

class StoreOrdersLoading extends StoreOrdersState {}

class StoreOrdersLoaded extends StoreOrdersState {
  final List<OrderModel> orders;
  StoreOrdersLoaded(this.orders);
}

class StoreOrdersError extends StoreOrdersState {
  final String message;
  StoreOrdersError(this.message);
}

class StoreOrdersBloc extends Bloc<StoreOrdersEvent, StoreOrdersState> {
  final OrderService _orderService;
  final StoreRealtimeService _realtimeService = StoreRealtimeService();
  StreamSubscription<StoreRealtimeEvent>? _realtimeSubscription;

  StoreOrdersBloc(this._orderService) : super(StoreOrdersInitial()) {
    on<LoadStoreOrders>(_onLoad);
    on<UpdateOrderStatus>(_onUpdateStatus);
    on<_RealtimeOrdersChanged>(_onRealtimeOrdersChanged);

    _realtimeSubscription = _realtimeService.events.listen((event) {
      developer.log('[StoreOrdersBloc] Received realtime event: ${event.type}',
          name: 'StoreOrders');
      if (event.type == StoreRealtimeEventType.newOrder ||
          event.type == StoreRealtimeEventType.orderAccepted ||
          event.type == StoreRealtimeEventType.orderStatusChanged) {
        add(_RealtimeOrdersChanged());
      }
    });

    _realtimeService.connect();
  }

  Future<void> _onLoad(
      LoadStoreOrders event, Emitter<StoreOrdersState> emit) async {
    emit(StoreOrdersLoading());
    try {
      final orders = await _orderService.getStoreOrders();
      emit(StoreOrdersLoaded(orders));
    } catch (e) {
      emit(StoreOrdersError(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
      UpdateOrderStatus event, Emitter<StoreOrdersState> emit) async {
    try {
      await _orderService.updateOrderStatus(event.orderId,
          newStatus: event.status);
      add(LoadStoreOrders());
    } catch (e) {
      emit(StoreOrdersError(e.toString()));
    }
  }

  Future<void> _onRealtimeOrdersChanged(
      _RealtimeOrdersChanged event, Emitter<StoreOrdersState> emit) async {
    // Avoid triggering duplicate fetches while one request is in-flight.
    if (state is StoreOrdersLoading) return;
    add(LoadStoreOrders());
  }

  @override
  Future<void> close() async {
    await _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    return super.close();
  }
}

// ============ PRODUCTS BLOC ============
abstract class StoreProductsEvent {}

/// Load products belonging to the current store.
/// Requires the store's ID so we call GET /products/store/{storeId}.
class LoadStoreProducts extends StoreProductsEvent {
  final int? storeId;
  LoadStoreProducts({this.storeId});
}

class CreateProduct extends StoreProductsEvent {
  final CreateProductRequest request;
  CreateProduct(this.request);
}

class UpdateProduct extends StoreProductsEvent {
  final String productId;
  final UpdateProductRequest request;
  UpdateProduct(this.productId, this.request);
}

class DeleteProduct extends StoreProductsEvent {
  final String productId;
  DeleteProduct(this.productId);
}

abstract class StoreProductsState {}

class StoreProductsInitial extends StoreProductsState {}

class StoreProductsLoading extends StoreProductsState {}

class StoreProductsLoaded extends StoreProductsState {
  final List<ProductModel> products;
  StoreProductsLoaded(this.products);
}

class StoreProductsError extends StoreProductsState {
  final String message;
  StoreProductsError(this.message);
}

class StoreProductsBloc extends Bloc<StoreProductsEvent, StoreProductsState> {
  final ProductService _productService;
  StoreProductsBloc(this._productService) : super(StoreProductsInitial()) {
    on<LoadStoreProducts>(_onLoad);
    on<CreateProduct>(_onCreate);
    on<UpdateProduct>(_onUpdate);
    on<DeleteProduct>(_onDelete);
  }

  int? _lastStoreId;

  Future<void> _onLoad(
      LoadStoreProducts event, Emitter<StoreProductsState> emit) async {
    emit(StoreProductsLoading());
    try {
      // Remember storeId for reload after CRUD
      if (event.storeId != null) _lastStoreId = event.storeId;

      List<ProductModel> products;
      if (_lastStoreId != null) {
        // ✅ FIX: Load only THIS store's products
        products =
            await _productService.getProductsByStore(_lastStoreId.toString());
      } else {
        emit(StoreProductsError('Không tìm thấy thông tin cửa hàng hiện tại'));
        return;
      }
      emit(StoreProductsLoaded(products));
    } catch (e) {
      emit(StoreProductsError(e.toString()));
    }
  }

  Future<void> _onCreate(
      CreateProduct event, Emitter<StoreProductsState> emit) async {
    try {
      await _productService.createProduct(event.request);
      add(LoadStoreProducts());
    } catch (e) {
      emit(StoreProductsError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateProduct event, Emitter<StoreProductsState> emit) async {
    try {
      await _productService.updateProduct(event.productId, event.request);
      add(LoadStoreProducts());
    } catch (e) {
      emit(StoreProductsError(e.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteProduct event, Emitter<StoreProductsState> emit) async {
    try {
      await _productService.deleteProduct(event.productId);
      add(LoadStoreProducts());
    } catch (e) {
      emit(StoreProductsError(e.toString()));
    }
  }
}

// ============ CATEGORIES BLOC ============
abstract class StoreCategoriesEvent {}

class LoadCategories extends StoreCategoriesEvent {}

abstract class StoreCategoriesState {}

class StoreCategoriesInitial extends StoreCategoriesState {}

class StoreCategoriesLoading extends StoreCategoriesState {}

class StoreCategoriesLoaded extends StoreCategoriesState {
  final List<CategoryModel> categories;
  StoreCategoriesLoaded(this.categories);
}

class StoreCategoriesError extends StoreCategoriesState {
  final String message;
  StoreCategoriesError(this.message);
}

class StoreCategoriesBloc
    extends Bloc<StoreCategoriesEvent, StoreCategoriesState> {
  final CategoryService _categoryService;
  StoreCategoriesBloc(this._categoryService) : super(StoreCategoriesInitial()) {
    on<LoadCategories>(_onLoad);
  }
  Future<void> _onLoad(
      LoadCategories event, Emitter<StoreCategoriesState> emit) async {
    emit(StoreCategoriesLoading());
    try {
      final categories = await _categoryService.getCategories();
      emit(StoreCategoriesLoaded(categories));
    } catch (e) {
      emit(StoreCategoriesError(e.toString()));
    }
  }
}

// ============ REVIEWS BLOC ============
abstract class StoreReviewsEvent {}

class LoadStoreReviews extends StoreReviewsEvent {
  final int storeId;
  LoadStoreReviews(this.storeId);
}

abstract class StoreReviewsState {}

class StoreReviewsInitial extends StoreReviewsState {}

class StoreReviewsLoading extends StoreReviewsState {}

class StoreReviewsLoaded extends StoreReviewsState {
  final List<ReviewModel> reviews;
  final StoreRatingModel? rating;
  StoreReviewsLoaded({required this.reviews, this.rating});
}

class StoreReviewsError extends StoreReviewsState {
  final String message;
  StoreReviewsError(this.message);
}

class StoreReviewsBloc extends Bloc<StoreReviewsEvent, StoreReviewsState> {
  final ReviewService _reviewService;
  StoreReviewsBloc(this._reviewService) : super(StoreReviewsInitial()) {
    on<LoadStoreReviews>(_onLoad);
  }
  Future<void> _onLoad(
      LoadStoreReviews event, Emitter<StoreReviewsState> emit) async {
    emit(StoreReviewsLoading());
    try {
      final results = await Future.wait([
        _reviewService.getStoreReviews(event.storeId),
        _reviewService.getStoreRating(event.storeId),
      ]);
      emit(StoreReviewsLoaded(
          reviews: results[0] as List<ReviewModel>,
          rating: results[1] as StoreRatingModel?));
    } catch (e) {
      emit(StoreReviewsError(e.toString()));
    }
  }
}

// ============ UNIT BLOC ============

abstract class UnitEvent {}

class LoadUnits extends UnitEvent {}

class LoadUnitCategories extends UnitEvent {}

class LoadUnitsByCategory extends UnitEvent {
  final int categoryId;
  LoadUnitsByCategory(this.categoryId);
}

abstract class UnitState {}

class UnitInitial extends UnitState {}

class UnitLoading extends UnitState {}

class UnitsLoaded extends UnitState {
  final List<Unit> units;
  UnitsLoaded(this.units);
}

class UnitCategoriesLoaded extends UnitState {
  final List<UnitCategory> categories;
  UnitCategoriesLoaded(this.categories);
}

class UnitsByCategoryLoaded extends UnitState {
  final Map<UnitCategory, List<Unit>> organizedUnits;
  UnitsByCategoryLoaded(this.organizedUnits);
}

class UnitError extends UnitState {
  final String message;
  UnitError(this.message);
}

class UnitBloc extends Bloc<UnitEvent, UnitState> {
  final UnitService _unitService;

  UnitBloc({UnitService? unitService})
      : _unitService = unitService ?? UnitService(),
        super(UnitInitial()) {
    on<LoadUnits>(_onLoadUnits);
    on<LoadUnitCategories>(_onLoadUnitCategories);
    on<LoadUnitsByCategory>(_onLoadUnitsByCategory);
  }

  Future<void> _onLoadUnits(LoadUnits event, Emitter<UnitState> emit) async {
    emit(UnitLoading());
    try {
      final units = await _unitService.getAllUnits();
      emit(UnitsLoaded(units));
    } catch (e) {
      emit(UnitError('Failed to load units: $e'));
    }
  }

  Future<void> _onLoadUnitCategories(
      LoadUnitCategories event, Emitter<UnitState> emit) async {
    emit(UnitLoading());
    try {
      final categories = await _unitService.getUnitCategories();
      emit(UnitCategoriesLoaded(categories));
    } catch (e) {
      emit(UnitError('Failed to load categories: $e'));
    }
  }

  Future<void> _onLoadUnitsByCategory(
      LoadUnitsByCategory event, Emitter<UnitState> emit) async {
    emit(UnitLoading());
    try {
      final organized = await _unitService.getUnitsOrganizedByCategory();
      emit(UnitsByCategoryLoaded(organized));
    } catch (e) {
      emit(UnitError('Failed to load units: $e'));
    }
  }
}
