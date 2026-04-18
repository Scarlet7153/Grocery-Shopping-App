import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../features/customer/home/data/home_api.dart';
import '../../../../features/customer/home/data/product_model.dart';
import '../../../../features/customer/home/data/review_api.dart';
import '../../../../features/customer/home/data/review_model.dart';
import '../../../../features/customer/home/data/store_model.dart';
import '../../shared/customer_product_list_card.dart';
import '../../shared/customer_state_view.dart';
import '../../shared/variant_selection_sheet.dart';
import '../../utils/customer_l10n.dart';
import 'product_detail_screen.dart';
import 'store_reviews_screen.dart';

class StoreProductsScreen extends StatefulWidget {
  const StoreProductsScreen({
    super.key,
    required this.store,
    required this.initialProducts,
  });

  final StoreModel store;
  final List<ProductModel> initialProducts;

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  final HomeApi _api = HomeApi();
  final ReviewApi _reviewApi = ReviewApi();

  bool _loading = false;
  String? _error;
  List<ProductModel> _products = const [];
  StoreRatingModel? _storeRating;
  bool _loadingRating = true;

  @override
  void initState() {
    super.initState();
    _products = _filterByStore(widget.initialProducts);
    if (_products.isEmpty) {
      _loadProducts();
    }
    _loadStoreRating();
  }

  Future<void> _loadStoreRating() async {
    try {
      final rating = await _reviewApi.getStoreRating(widget.store.id);
      if (mounted) {
        setState(() {
          _storeRating = rating;
          _loadingRating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingRating = false);
      }
    }
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
        _products = _filterByStore(products);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.tr(
          vi: 'Không thể tải sản phẩm của cửa hàng',
          en: 'Unable to load store products',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ProductModel> _filterByStore(List<ProductModel> source) {
    final target = widget.store.storeName.trim().toLowerCase();
    return source.where((p) {
      final current = p.storeName.trim().toLowerCase();
      return current == target;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.store.storeName)),
      body: Container(
        color: scheme.surfaceContainerLowest,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? CustomerStateView.error(
                    compact: true,
                    message: _error!,
                    onAction: _loadProducts,
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildStoreHeader(),
          const SizedBox(height: 12),
          ..._products.map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomerProductListCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  onBuyNow: () async {
                    if (product.units.length > 1) {
                      await showVariantSelectionSheet(context, product);
                    } else {
                      _addToCart(product);
                    }
                  },
                  customerAddress: AuthSession.useCurrentLocation
                      ? null
                      : AuthSession.address,
                  customerLatitude: AuthSession.selectedLatitude,
                  customerLongitude: AuthSession.selectedLongitude,
                  storeAddress: widget.store.address,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    final scheme = Theme.of(context).colorScheme;

    if (_loadingRating) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                context.tr(
                    vi: 'Đang tải đánh giá...', en: 'Loading ratings...'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final rating = _storeRating;
    if (rating == null) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _openReviews(),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rating.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: Colors.amber, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          context.tr(
                            vi: '(${rating.totalReviews} đánh giá)',
                            en: '(${rating.totalReviews} reviews)',
                          ),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        vi: 'Nhấn để xem đánh giá',
                        en: 'Tap to view reviews',
                      ),
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreReviewsScreen(
          storeId: widget.store.id,
          storeName: widget.store.storeName,
        ),
      ),
    );
  }
}
