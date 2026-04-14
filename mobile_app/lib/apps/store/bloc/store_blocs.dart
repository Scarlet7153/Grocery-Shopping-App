import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/store/data/store_service.dart';
import '../../../features/store/data/store_model.dart';
import '../../../features/orders/data/order_service.dart';
import '../../../features/orders/data/order_model.dart';
import '../../../features/products/data/product_service.dart';
import '../../../features/products/data/product_model.dart';
import '../../../features/products/data/category_service.dart';
import '../../../features/products/data/category_model.dart';
import '../../../features/review/data/review_service.dart';
import '../../../features/review/data/review_model.dart';

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
  UpdateStoreProfileEvent(
      {required this.storeId, required this.storeName, required this.address});
}

abstract class StoreDashboardState {}

class StoreDashboardInitial extends StoreDashboardState {}

class StoreDashboardLoading extends StoreDashboardState {}

class StoreDashboardLoaded extends StoreDashboardState {
  final StoreModel store;
  StoreDashboardLoaded(this.store);
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
    try {
      await _storeService.toggleStoreStatus(event.storeId);
      add(LoadStoreDashboard());
    } catch (e) {
      emit(StoreDashboardError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateStoreProfileEvent event, Emitter<StoreDashboardState> emit) async {
    try {
      await _storeService.updateStoreProfile(
          event.storeId,
          UpdateStoreProfileRequest(
              storeName: event.storeName, address: event.address));
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
  StoreOrdersBloc(this._orderService) : super(StoreOrdersInitial()) {
    on<LoadStoreOrders>(_onLoad);
    on<UpdateOrderStatus>(_onUpdateStatus);
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
        // Fallback: load all (should not happen in store app)
        products = await _productService.getProducts();
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
  StoreCategoriesBloc(this._categoryService)
      : super(StoreCategoriesInitial()) {
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
