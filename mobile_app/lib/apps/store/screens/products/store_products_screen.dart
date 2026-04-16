import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../core/api/api_error.dart';
import '../../../../features/products/data/category_model.dart';
import '../../../../features/products/data/unit_model.dart';
import '../../../../features/products/data/unit_service.dart';
import '../../../../features/products/data/product_service.dart';
import '../../bloc/store_blocs.dart';
import '../../../../features/products/data/product_model.dart';
import 'store_product_detail_screen.dart';
import 'store_product_create_screen.dart';
import '../../utils/store_localizations.dart';

class StoreProductsScreen extends StatefulWidget {
  const StoreProductsScreen({super.key});
  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  final UnitService _unitService = UnitService();
  final ProductService _productService = ProductService();
  List<Unit> _dbUnits = [];
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  String _searchQuery = '';
  int? _requestedStoreId;

  @override
  void initState() {
    super.initState();
    _loadUnitsFromDb();
    // Load categories from API
    context.read<StoreCategoriesBloc>().add(LoadCategories());
    // Load products scoped to the current store
    _loadStoreProducts();
  }

  Future<void> _loadUnitsFromDb() async {
    try {
      final units = await _unitService.getAllUnits();
      if (!mounted) {
        return;
      }
      setState(() {
        _dbUnits = units;
      });
    } catch (_) {
      // Keep previous units and use fallback code when API is temporarily unavailable.
    }
  }

  List<String> get _unitCodes {
    if (_dbUnits.isEmpty) {
      return const ['kg'];
    }
    return _dbUnits.map((u) => u.code).toList();
  }

  String get _defaultUnitCode => _unitCodes.first;

  String _unitLabel(String code) {
    final matches = _dbUnits.where((u) => u.code == code);
    if (matches.isEmpty) {
      return code;
    }
    final unit = matches.first;
    return unit.symbol.isNotEmpty ? '${unit.name} (${unit.symbol})' : unit.name;
  }

  void _loadStoreProducts() {
    final dashState = context.read<StoreDashboardBloc>().state;
    final storeId =
        dashState is StoreDashboardLoaded ? dashState.store.id : null;

    if (storeId == null) {
      context.read<StoreDashboardBloc>().add(LoadStoreDashboard());
      return;
    }

    if (_requestedStoreId == storeId) {
      return;
    }

    _requestedStoreId = storeId;
    context.read<StoreProductsBloc>().add(LoadStoreProducts(storeId: storeId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    return products.where((p) {
      final matchesCategory = _selectedCategoryId == null ||
          p.category == _getCategoryNameById(_selectedCategoryId!);
      final matchesSearch = _searchQuery.isEmpty ||
          (p.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  String? _getCategoryNameById(int id) {
    final state = context.read<StoreCategoriesBloc>().state;
    if (state is StoreCategoriesLoaded) {
      final cat = state.categories.where((c) => c.id == id);
      return cat.isNotEmpty ? cat.first.name : null;
    }
    return null;
  }

  List<UpdateProductUnitRequest> _mapUnitsForUpdate(ProductModel product) {
    if (product.units != null && product.units!.isNotEmpty) {
      return product.units!
          .map((u) => UpdateProductUnitRequest(
                id: u.id,
                unitCode: u.unit.code,
                unitName: u.displayName,
                baseQuantity: u.baseQuantity,
                baseUnit: u.baseUnit,
                price: u.price,
                stockQuantity: u.stockQuantity,
                isDefault: u.isDefault,
                isActive: u.isActive,
              ))
          .toList();
    }

    return [
      UpdateProductUnitRequest(
        id: null,
        unitCode: _defaultUnitCode,
        unitName: _unitLabel(_defaultUnitCode),
        baseQuantity: null,
        baseUnit: null,
        price: product.price ?? 0,
        stockQuantity: product.stock ?? 0,
        isDefault: true,
        isActive: true,
      )
    ];
  }

  Future<void> _openCreateProductPage(List<CategoryModel> categories) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProductCreateScreen(categories: categories),
      ),
    );

    if (created == true && mounted) {
      _loadStoreProducts();
      final loc = context.storeLoc;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.tr('add_product')} ${loc.tr('success')}'),
          backgroundColor: StoreTheme.primaryColor,
        ),
      );
    }
  }

  void _showDeleteDialog(ProductModel product) {
    final loc = context.storeLoc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('delete_product')),
        content: Text(loc
            .tr('delete_confirm')
            .replaceFirst('{name}', product.name ?? '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context
                  .read<StoreProductsBloc>()
                  .add(DeleteProduct(product.id.toString()));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(loc.tr('delete_product_success')),
                    backgroundColor: StoreTheme.primaryColor),
              );
            },
            child: Text(loc.tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.storeLoc;
    return BlocListener<StoreDashboardBloc, StoreDashboardState>(
      listener: (context, state) {
        if (state is StoreDashboardLoaded) {
          final storeId = state.store.id;
          if (storeId != null && _requestedStoreId != storeId) {
            _requestedStoreId = storeId;
            context
                .read<StoreProductsBloc>()
                .add(LoadStoreProducts(storeId: storeId));
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
            title: Text(loc.tr('products')),
            backgroundColor: StoreTheme.primaryColor,
            foregroundColor: Colors.white),
        floatingActionButton:
            BlocBuilder<StoreCategoriesBloc, StoreCategoriesState>(
          builder: (context, catState) {
            final categories = catState is StoreCategoriesLoaded
                ? catState.categories
                : <CategoryModel>[];
            return FloatingActionButton(
              backgroundColor: StoreTheme.primaryColor,
              onPressed: () => _openCreateProductPage(categories),
              child: const Icon(Icons.add, color: Colors.white),
            );
          },
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: loc.tr('search_products'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  // ✅ Dynamic categories from API
                  BlocBuilder<StoreCategoriesBloc, StoreCategoriesState>(
                    builder: (context, catState) {
                      final categories = catState is StoreCategoriesLoaded
                          ? catState.categories
                          : <CategoryModel>[];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryChip(
                                loc.tr('all'),
                                null,
                                _selectedCategoryId,
                                (c) => setState(() => _selectedCategoryId = c)),
                            ...categories.map((c) => _CategoryChip(
                                c.name ?? '',
                                c.id,
                                _selectedCategoryId,
                                (v) =>
                                    setState(() => _selectedCategoryId = v))),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<StoreProductsBloc, StoreProductsState>(
                builder: (context, state) {
                  if (state is StoreProductsLoading)
                    return const Center(child: CircularProgressIndicator());
                  if (state is StoreProductsError)
                    return Center(child: Text(state.message));
                  if (state is StoreProductsLoaded) {
                    final filtered = _filterProducts(state.products);
                    if (filtered.isEmpty) {
                      return Center(child: Text(loc.tr('no_products')));
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _loadStoreProducts(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final product = filtered[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreProductDetailScreen(
                                  product: product,
                                  onEdit: (p) async {
                                    try {
                                      await _productService.updateProduct(
                                        p.id.toString(),
                                        UpdateProductRequest(
                                          name: p.name,
                                          description: p.description,
                                          units: _mapUnitsForUpdate(p),
                                        ),
                                      );

                                      if (mounted &&
                                          _requestedStoreId != null) {
                                        context.read<StoreProductsBloc>().add(
                                              LoadStoreProducts(
                                                  storeId: _requestedStoreId),
                                            );
                                      }
                                      return true;
                                    } catch (e) {
                                      if (!mounted) return false;
                                      final message = e is ApiException
                                          ? (e.serverMessage ?? e.message)
                                          : e.toString();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${loc.tr('save_failed')}: $message')),
                                      );
                                      return false;
                                    }
                                  },
                                  onDelete: (id) {
                                    context
                                        .read<StoreProductsBloc>()
                                        .add(DeleteProduct(id));
                                  },
                                ),
                              ),
                            ),
                            child: Dismissible(
                              key: Key(product.id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                _showDeleteDialog(product);
                                return false;
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    // Show product image or placeholder
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: product.imageUrl != null &&
                                              product.imageUrl!.isNotEmpty &&
                                              !product.imageUrl!
                                                  .contains('example.com')
                                          ? Image.network(
                                              product.imageUrl!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _productPlaceholder(),
                                            )
                                          : _productPlaceholder(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              product.name ?? loc.tr('product'),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          if (product.category != null)
                                            Text(product.category!,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600])),
                                          Text(
                                              '${product.price?.toStringAsFixed(0) ?? 0}đ',
                                              style: const TextStyle(
                                                  color:
                                                      StoreTheme.primaryColor,
                                                  fontWeight: FontWeight.w600)),
                                          if (product.stock != null)
                                            Text(
                                                '${loc.tr('stock')}: ${product.stock}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600])),
                                        ])),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productPlaceholder() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.shopping_bag, color: StoreTheme.primaryColor),
      );
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int? categoryId;
  final int? selectedId;
  final Function(int?) onTap;
  const _CategoryChip(this.label, this.categoryId, this.selectedId, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = categoryId == selectedId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(categoryId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: isSelected
                ? StoreTheme.primaryColor
                : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20)),
          child: Text(label,
              style: TextStyle(
                color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14)),
        ),
      ),
    );
  }
}
