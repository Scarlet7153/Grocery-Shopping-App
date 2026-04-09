import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/products/data/product_model.dart';
import '../../../features/products/data/product_service.dart';

/// EVENTS

abstract class StoreProductsEvent {}

class LoadStoreProducts extends StoreProductsEvent {
  final int? page;
  final int? limit;
  final String? category;
  final String? search;

  LoadStoreProducts({this.page, this.limit, this.category, this.search});
}

class CreateStoreProduct extends StoreProductsEvent {
  final CreateProductRequest request;

  CreateStoreProduct(this.request);
}

class UpdateStoreProduct extends StoreProductsEvent {
  final String productId;
  final UpdateProductRequest request;

  UpdateStoreProduct(this.productId, this.request);
}

class DeleteStoreProduct extends StoreProductsEvent {
  final String productId;

  DeleteStoreProduct(this.productId);
}

/// STATES

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

/// Bloc that fetches and mutates products via [ProductService].
class StoreProductsBloc extends Bloc<StoreProductsEvent, StoreProductsState> {
  StoreProductsBloc(this._productService) : super(StoreProductsInitial()) {
    on<LoadStoreProducts>(_onLoad);
    on<CreateStoreProduct>(_onCreate);
    on<UpdateStoreProduct>(_onUpdate);
    on<DeleteStoreProduct>(_onDelete);
  }

  final ProductService _productService;

  Future<void> _onLoad(
    LoadStoreProducts event,
    Emitter<StoreProductsState> emit,
  ) async {
    emit(StoreProductsLoading());
    try {
      final list = await _productService.getProducts(
        page: event.page,
        limit: event.limit,
        category: event.category,
        search: event.search,
      );
      emit(StoreProductsLoaded(list));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
    }
  }

  Future<void> _onCreate(
    CreateStoreProduct event,
    Emitter<StoreProductsState> emit,
  ) async {
    final current = state;
    if (current is! StoreProductsLoaded) return;
    try {
      await _productService.createProduct(event.request);
      final list = await _productService.getProducts();
      emit(StoreProductsLoaded(list));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
      emit(StoreProductsLoaded(current.products));
    }
  }

  Future<void> _onUpdate(
    UpdateStoreProduct event,
    Emitter<StoreProductsState> emit,
  ) async {
    final current = state;
    if (current is! StoreProductsLoaded) return;
    try {
      await _productService.updateProduct(event.productId, event.request);
      final list = await _productService.getProducts();
      emit(StoreProductsLoaded(list));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
      emit(StoreProductsLoaded(current.products));
    }
  }

  Future<void> _onDelete(
    DeleteStoreProduct event,
    Emitter<StoreProductsState> emit,
  ) async {
    final current = state;
    if (current is! StoreProductsLoaded) return;
    try {
      await _productService.deleteProduct(event.productId);
      final list = current.products
          .where((p) => p.id != event.productId)
          .toList();
      emit(StoreProductsLoaded(list));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreProductsError(message));
      emit(StoreProductsLoaded(current.products));
    }
  }
}
