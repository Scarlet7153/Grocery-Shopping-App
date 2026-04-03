import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/customer/home/data/category_model.dart';
import '../../../features/customer/home/data/home_api.dart';
import '../../../features/customer/home/data/product_model.dart';
import '../../../features/customer/home/data/store_model.dart';

/// EVENT

abstract class CustomerHomeEvent {}

class LoadHomeEvent extends CustomerHomeEvent {}
class RefreshHomeEvent extends CustomerHomeEvent {}
class SearchProductsEvent extends CustomerHomeEvent {
  final String keyword;

  SearchProductsEvent(this.keyword);
}

/// STATE

abstract class CustomerHomeState {}

class CustomerHomeInitial extends CustomerHomeState {}

class CustomerHomeLoading extends CustomerHomeState {}

class CustomerHomeLoaded extends CustomerHomeState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final List<StoreModel> featuredStores;
  final List<ProductModel> searchSuggestions;

  CustomerHomeLoaded({
    required this.products,
    required this.categories,
    required this.featuredStores,
    required this.searchSuggestions,
  });
}

/// BLOC

class CustomerHomeBloc extends Bloc<CustomerHomeEvent, CustomerHomeState> {
  final HomeApi api = HomeApi();

  CustomerHomeBloc() : super(CustomerHomeInitial()) {
    on<LoadHomeEvent>(_onLoadHome);
    on<RefreshHomeEvent>(_onRefreshHome);
    on<SearchProductsEvent>(_onSearchProducts);
  }

  Future<void> _onLoadHome(
    LoadHomeEvent event,
    Emitter<CustomerHomeState> emit,
  ) async {
    emit(CustomerHomeLoading());

    try {
      final products = await api.getProducts();
      final categories = await api.getCategories();
      final featuredStores = await api.getFeaturedStores();

      emit(
        CustomerHomeLoaded(
          products: products,
          categories: categories,
          featuredStores: featuredStores,
          searchSuggestions: const [],
        ),
      );
    } catch (e) {
      emit(
        CustomerHomeLoaded(
          products: const [],
          categories: const [],
          featuredStores: const [],
          searchSuggestions: const [],
        ),
      );
    }
  }

  Future<void> _onRefreshHome(
    RefreshHomeEvent event,
    Emitter<CustomerHomeState> emit,
  ) async {
    try {
      final products = await api.getProducts();
      final categories = await api.getCategories();
      final featuredStores = await api.getFeaturedStores();

      emit(
        CustomerHomeLoaded(
          products: products,
          categories: categories,
          featuredStores: featuredStores,
          searchSuggestions: const [],
        ),
      );
    } catch (e) {
      emit(
        CustomerHomeLoaded(
          products: const [],
          categories: const [],
          featuredStores: const [],
          searchSuggestions: const [],
        ),
      );
    }
  }

  Future<void> _onSearchProducts(
    SearchProductsEvent event,
    Emitter<CustomerHomeState> emit,
  ) async {
    if (state is! CustomerHomeLoaded) return;

    final current = state as CustomerHomeLoaded;
    final keyword = event.keyword.trim();

    if (keyword.isEmpty) {
      emit(
        CustomerHomeLoaded(
          products: current.products,
          categories: current.categories,
          featuredStores: current.featuredStores,
          searchSuggestions: const [],
        ),
      );
      return;
    }

    try {
      final suggestions = await api.searchProducts(keyword);
      emit(
        CustomerHomeLoaded(
          products: current.products,
          categories: current.categories,
          featuredStores: current.featuredStores,
          searchSuggestions: suggestions,
        ),
      );
    } catch (e) {
      emit(
        CustomerHomeLoaded(
          products: current.products,
          categories: current.categories,
          featuredStores: current.featuredStores,
          searchSuggestions: const [],
        ),
      );
    }
  }
}
