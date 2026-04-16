import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../features/customer/home/data/home_api.dart';
import '../../../../features/customer/home/data/product_model.dart';
import '../../shared/customer_product_list_card.dart';
import '../../shared/customer_state_view.dart';
import '../../utils/customer_l10n.dart';
import 'product_detail_screen.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({
    super.key,
    required this.initialProducts,
    this.initialCategories = const [],
    this.initialSelectedCategory,
  });

  final List<ProductModel> initialProducts;
  final List<String> initialCategories;
  final String? initialSelectedCategory;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final HomeApi _api = HomeApi();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<ProductModel> _products = const [];
  List<String> _categories = const [];
  String? _selectedCategory;
  final Map<String, String> _storeAddressByName = {};

  @override
  void initState() {
    super.initState();
    _products = widget.initialProducts;
    _selectedCategory = widget.initialSelectedCategory;
    _syncCategories();
    _loadStoreAddresses();
    if (_products.isEmpty) {
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await _api.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _syncCategories();
      });
      await _loadStoreAddresses();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.tr(
          vi: 'Không thể tải danh sách sản phẩm',
          en: 'Unable to load product list',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadStoreAddresses() async {
    try {
      final stores = await _api.getFeaturedStores();
      if (!mounted) return;
      setState(() {
        _storeAddressByName
          ..clear()
          ..addEntries(
            stores.map(
              (store) => MapEntry(
                store.storeName.trim().toLowerCase(),
                store.address,
              ),
            ),
          );
      });
    } catch (_) {
      // Keep silent if store address list cannot be loaded.
    }
  }

  void _addToCart(ProductModel product) {
    final defaultUnit = product.units.isNotEmpty ? product.units.first : null;
    if (defaultUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.tr(
              vi: 'Sản phẩm chưa có biến thể bán',
              en: 'This product has no purchasable variant',
            ),
          ),
        ),
      );
      return;
    }
    if (defaultUnit.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.tr(
              vi: 'Sản phẩm hiện đã hết hàng',
              en: 'This product is out of stock',
            ),
          ),
        ),
      );
      return;
    }

    CartSession.addProduct(
      product,
      productUnitMappingId: defaultUnit.id,
      unitPrice: defaultUnit.price,
      unitLabel: defaultUnit.unitName,
      stockQuantity: defaultUnit.stockQuantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content:
            Text(context.tr(vi: 'Đã thêm vào giỏ hàng', en: 'Added to cart')),
      ),
    );
  }

  void _syncCategories() {
    final names = <String>{
      ...widget.initialCategories
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty),
      ..._products.map((p) => p.categoryName.trim()).where((e) => e.isNotEmpty),
    }.toList();

    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _categories = names;

    if (_selectedCategory != null &&
        !_categories.any(
          (c) => c.toLowerCase() == _selectedCategory!.trim().toLowerCase(),
        )) {
      _selectedCategory = null;
    }
  }

  IconData _categoryIcon(String name) {
    final key = name.toLowerCase();
    if (key.contains('rau')) return Icons.grass;
    if (key.contains('cu')) return Icons.spa;
    if (key.contains('trai')) return Icons.apple;
    if (key.contains('thit')) return Icons.set_meal;
    if (key.contains('ca')) return Icons.lunch_dining;
    if (key.contains('uong')) return Icons.local_drink;
    return Icons.category;
  }

  Widget _categoryChip(String name, bool selected, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: selected ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.1), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.22)
                    : scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(name),
                size: 18,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keyword = _searchController.text.trim().toLowerCase();

    final byCategory =
        (_selectedCategory == null || _selectedCategory!.trim().isEmpty)
            ? _products
            : _products
                .where(
                  (p) =>
                      p.categoryName.trim().toLowerCase() ==
                      _selectedCategory!.trim().toLowerCase(),
                )
                .toList();

    final filtered = keyword.isEmpty
        ? byCategory
        : byCategory.where((p) {
            final name = p.name.toLowerCase();
            final store = p.storeName.toLowerCase();
            final category = p.categoryName.toLowerCase();
            return name.contains(keyword) ||
                store.contains(keyword) ||
                category.contains(keyword);
          }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _selectedCategory);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _selectedCategory);
            },
          ),
          title: Text(context.tr(vi: 'Tất cả sản phẩm', en: 'All products')),
        ),
        body: Container(
          color: scheme.surfaceContainerLowest,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.tr(
                      vi: 'Tìm theo tên sản phẩm, cửa hàng, danh mục...',
                      en: 'Search by product, store, or category...',
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _categoryChip(
                          context.tr(vi: 'Tất cả', en: 'All'),
                          _selectedCategory == null,
                          () {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                        );
                      }

                      final category = _categories[index - 1];
                      final selected =
                          _selectedCategory?.trim().toLowerCase() ==
                              category.trim().toLowerCase();
                      return _categoryChip(category, selected, () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      });
                    },
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_error != null)
                        ? CustomerStateView.error(
                            compact: true,
                            message: _error!,
                            onAction: _loadProducts,
                          )
                        : filtered.isEmpty
                            ? CustomerStateView.empty(
                                compact: true,
                                title: context.tr(
                                  vi: 'Không có sản phẩm phù hợp',
                                  en: 'No matching products',
                                ),
                                message: context.tr(
                                  vi: 'Hãy thử từ khóa khác để tìm sản phẩm.',
                                  en: 'Try another keyword to find products.',
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadProducts,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final product = filtered[index];
                                    return CustomerProductListCard(
                                      product: product,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(
                                                product: product),
                                          ),
                                        );
                                      },
                                      onBuyNow: () => _addToCart(product),
                                      customerAddress:
                                          AuthSession.useCurrentLocation
                                              ? null
                                              : AuthSession.address,
                                      customerLatitude:
                                          AuthSession.selectedLatitude,
                                      customerLongitude:
                                          AuthSession.selectedLongitude,
                                      storeAddress: _storeAddressByName[product
                                          .storeName
                                          .trim()
                                          .toLowerCase()],
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
