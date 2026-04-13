import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/products/data/product_model.dart';
import '../data/store_demo_product_seed.dart';
import '../repository/store_repository.dart';

/// EVENTS

abstract class StoreProductsEvent {}

class LoadStoreProducts extends StoreProductsEvent {
  final String token;
  final int? page;
  final int? limit;
  final String? category;
  final String? search;

  LoadStoreProducts({
    required this.token,
    this.page,
    this.limit,
    this.category,
    this.search,
  });
}

class StoreCreateProductParams {
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool markHiddenAfterCreate;
  final List<int>? pendingImageBytes;
  final String? pendingImageFilename;

  const StoreCreateProductParams({
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.markHiddenAfterCreate = false,
    this.pendingImageBytes,
    this.pendingImageFilename,
  });
}

class CreateStoreProduct extends StoreProductsEvent {
  final String token;
  final StoreCreateProductParams params;

  CreateStoreProduct({required this.token, required this.params});
}

/// Lưu chỉnh sửa: upload ảnh local (nếu có) rồi PUT metadata (tên, mô tả).
class SaveStoreProductEdit extends StoreProductsEvent {
  final String token;
  final String productId;
  final String name;
  final String description;
  final List<int>? newImageBytes;
  final String? newImageFilename;

  SaveStoreProductEdit({
    required this.token,
    required this.productId,
    required this.name,
    required this.description,
    this.newImageBytes,
    this.newImageFilename,
  });
}

/// PATCH /products/{id}/toggle-status — không body
class ToggleProductVisibility extends StoreProductsEvent {
  final String token;
  final String productId;

  ToggleProductVisibility(this.token, this.productId);
}

class DeleteStoreProduct extends StoreProductsEvent {
  final String token;
  final String productId;

  DeleteStoreProduct(this.token, this.productId);
}

class ClearStoreProductsMessage extends StoreProductsEvent {}

/// STATES

abstract class StoreProductsState {}

class StoreProductsInitial extends StoreProductsState {}

class StoreProductsLoading extends StoreProductsState {}

class StoreProductsLoaded extends StoreProductsState {
  final List<ProductModel> products;
  final List<int> stockTotals;
  final String? successMessage;

  StoreProductsLoaded(
    this.products,
    this.stockTotals, {
    this.successMessage,
  });
}

class StoreProductsError extends StoreProductsState {
  final String message;

  StoreProductsError(this.message);
}

/// Bloc: GET /products/store/{id}, seed có khóa chuỗi để tránh race.
class StoreProductsBloc extends Bloc<StoreProductsEvent, StoreProductsState> {
  StoreProductsBloc(this._repository) : super(StoreProductsInitial()) {
    on<LoadStoreProducts>(_onLoad);
    on<CreateStoreProduct>(_onCreate);
    on<SaveStoreProductEdit>(_onSaveEdit);
    on<ToggleProductVisibility>(_onToggleVisibility);
    on<DeleteStoreProduct>(_onDelete);
    on<ClearStoreProductsMessage>(_onClearMessage);
  }

  final StoreRepository _repository;

  /// Một chuỗi tải duy nhất — tránh seed song song.
  static Future<void> _serial = Future.value();

  int? _storeId;

  bool _sessionDemoSeedAttempted = false;

  Future<int?> _resolveStoreId(String token) async {
    if (_storeId != null) return _storeId;
    final m = await _repository.getMyStore(token);
    final id = _repository.parseStoreId(m);
    _storeId = id;
    return id;
  }

  Future<StoreProductsFetchResult> _reloadResult(String token) async {
    final id = await _resolveStoreId(token);
    if (id == null) {
      throw Exception('Không xác định được cửa hàng');
    }
    return _repository.fetchProductsForStoreWithStocks(
      token: token,
      storeId: id,
    );
  }

  Future<void> _onLoad(
    LoadStoreProducts event,
    Emitter<StoreProductsState> emit,
  ) async {
    await (_serial = _serial.then((_) async {
      emit(StoreProductsLoading());
      try {
        _storeId = null;
        final id = await _resolveStoreId(event.token);
        if (id == null) {
          emit(StoreProductsError('Không tải được thông tin cửa hàng'));
          return;
        }
        var result = await _repository.fetchProductsForStoreWithStocks(
          token: event.token,
          storeId: id,
        );
        await _repository.removeDuplicateDemoProducts(
          token: event.token,
          products: result.products,
        );
        result = await _repository.fetchProductsForStoreWithStocks(
          token: event.token,
          storeId: id,
        );
        var list = result.products;
        var stocks = result.stockTotals;
        final seeded = await _maybeInsertDemoProductsIfNeeded(
          event.token,
          id,
          list,
        );
        if (seeded != null) {
          list = seeded.products;
          stocks = seeded.stockTotals;
        }
        emit(StoreProductsLoaded(list, stocks));
      } catch (e) {
        final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        emit(StoreProductsError(message));
      }
    }));
  }

  static String _demoSeededPrefsKey(int storeId) =>
      'store_app_demo_products_v1_seeded_$storeId';

  Future<StoreProductsFetchResult?> _maybeInsertDemoProductsIfNeeded(
    String token,
    int storeId,
    List<ProductModel> list,
  ) async {
    if (list.isNotEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final seededKey = _demoSeededPrefsKey(storeId);
    if (prefs.getBool(seededKey) == true) return null;
    if (_sessionDemoSeedAttempted) return null;
    try {
      for (final row in kStoreDemoProducts) {
        await _repository.createProductForStore(
          token: token,
          name: row.name,
          description: row.description,
          price: row.price,
          stock: row.stock,
          imageUrl: null,
        );
      }
      await prefs.setBool(seededKey, true);
      return _repository.fetchProductsForStoreWithStocks(
        token: token,
        storeId: storeId,
      );
    } catch (e) {
      _sessionDemoSeedAttempted = true;
      rethrow;
    }
  }

  Future<void> _onCreate(
    CreateStoreProduct event,
    Emitter<StoreProductsState> emit,
  ) async {
    final previous = state is StoreProductsLoaded
        ? (state as StoreProductsLoaded)
        : null;
    try {
      final id = await _repository.createProductForStore(
        token: event.token,
        name: event.params.name,
        description: event.params.description,
        price: event.params.price,
        stock: event.params.stock,
        imageUrl: event.params.imageUrl,
      );
      if (id != null) {
        final bytes = event.params.pendingImageBytes;
        if (bytes != null && bytes.isNotEmpty) {
          try {
            await _repository.uploadProductImage(
              token: event.token,
              productId: id.toString(),
              bytes: bytes,
              filename: event.params.pendingImageFilename ?? 'san-pham.jpg',
            );
          } catch (e) {
            final msg = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
            emit(StoreProductsError(
              'Đã tạo sản phẩm nhưng upload ảnh thất bại: $msg',
            ));
            if (previous != null) {
              emit(StoreProductsLoaded(previous.products, previous.stockTotals));
            }
            return;
          }
        }
        if (event.params.markHiddenAfterCreate) {
          try {
            await _repository.toggleProductStatus(
              token: event.token,
              productId: id,
            );
          } catch (_) {}
        }
      }
      final result = await _reloadResult(event.token);
      emit(StoreProductsLoaded(
        result.products,
        result.stockTotals,
        successMessage: 'Đã thêm sản phẩm.',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
      if (previous != null) {
        emit(StoreProductsLoaded(previous.products, previous.stockTotals));
      }
    }
  }

  Future<void> _onSaveEdit(
    SaveStoreProductEdit event,
    Emitter<StoreProductsState> emit,
  ) async {
    final current = state;
    if (current is! StoreProductsLoaded) return;
    try {
      final bytes = event.newImageBytes;
      if (bytes != null && bytes.isNotEmpty) {
        await _repository.uploadProductImage(
          token: event.token,
          productId: event.productId,
          bytes: bytes,
          filename: event.newImageFilename ?? 'san-pham.jpg',
        );
      }
      await _repository.updateProductMetadata(
        token: event.token,
        productId: event.productId,
        name: event.name,
        description: event.description,
      );
      final result = await _reloadResult(event.token);
      emit(StoreProductsLoaded(
        result.products,
        result.stockTotals,
        successMessage: 'Đã cập nhật sản phẩm.',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
      emit(StoreProductsLoaded(current.products, current.stockTotals));
    }
  }

  Future<void> _onToggleVisibility(
    ToggleProductVisibility event,
    Emitter<StoreProductsState> emit,
  ) async {
    final current = state;
    if (current is! StoreProductsLoaded) return;
    try {
      final pid = int.tryParse(event.productId);
      if (pid == null) {
        emit(StoreProductsError('Mã sản phẩm không hợp lệ'));
        emit(StoreProductsLoaded(current.products, current.stockTotals));
        return;
      }
      await _repository.toggleProductStatus(
        token: event.token,
        productId: pid,
      );
      final result = await _reloadResult(event.token);
      emit(StoreProductsLoaded(
        result.products,
        result.stockTotals,
        successMessage: 'Đã cập nhật trạng thái hiển thị.',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
      emit(StoreProductsLoaded(current.products, current.stockTotals));
    }
  }

  Future<void> _onDelete(
    DeleteStoreProduct event,
    Emitter<StoreProductsState> emit,
  ) async {
    final current = state;
    if (current is! StoreProductsLoaded) return;
    try {
      await _repository.deleteProduct(
        token: event.token,
        productId: event.productId,
      );
      final result = await _reloadResult(event.token);
      emit(StoreProductsLoaded(result.products, result.stockTotals));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
      emit(StoreProductsLoaded(current.products, current.stockTotals));
    }
  }

  void _onClearMessage(
    ClearStoreProductsMessage event,
    Emitter<StoreProductsState> emit,
  ) {
    final s = state;
    if (s is StoreProductsLoaded && s.successMessage != null) {
      emit(StoreProductsLoaded(s.products, s.stockTotals));
    }
  }
}
