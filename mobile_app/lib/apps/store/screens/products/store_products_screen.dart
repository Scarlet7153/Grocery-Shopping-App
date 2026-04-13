import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/ui/ui_constants.dart';
import 'package:grocery_shopping_app/features/products/data/product_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../block/store_products_bloc.dart';
import '../../widgets/scale_on_tap.dart';

/// Design system — merchant UI (#00B14F)
const Color _kPrimary = Color(0xFF00B14F);
const Color _kPrimaryLight = Color(0xFFE8F5E9);
const Color _kSurface = Color(0xFFF5F6FA);
const Color _kCardShadow = Color(0x0A000000);
const double _kImageWidth = 300;
const double _kImageHeight = 140;

/// Decode size for Flutter Web (max ~600px), giảm memory
const int _kCacheWidth = 600;
const int _kCacheHeight = 280;

/// Ngưỡng tồn: "Sắp hết" = (0, 20], "Còn hàng" = > 20 (sản phẩm đang hiển thị).
const int _kLowStockMax = 20;
const int _kSearchDebounceMs = 300;

/// Fallback khi không có ảnh theo tên. Path chuẩn: assets/products/<filename>.jpg
const String kDefaultProductImage = 'assets/products/default.jpg';

/// Map tên sản phẩm (tiếng Việt) -> đường dẫn asset. Chỉ các sản phẩm có ảnh trong assets/products/.
const Map<String, String> productImages = {
  'Táo Mỹ': 'assets/products/tao_my.jpg',
  'Chuối': 'assets/products/chuoi.jpg',
  'Cam': 'assets/products/cam.jpg',
  'Xoài': 'assets/products/xoai.jpg',
  'Dưa hấu': 'assets/products/dua_hau.jpg',
  'Cà chua': 'assets/products/ca_chua.jpg',
  'Bắp cải': 'assets/products/bap_cai.jpg',
  'Nho': 'assets/products/nho.jpg',
  'Lê': 'assets/products/le.jpg',
  'Thanh long': 'assets/products/thanh_long.jpg',
  'Ổi': 'assets/products/oi.jpg',
  'Gừng': 'assets/products/gung.jpg',
  'Tỏi': 'assets/products/toi.jpg',
  'Cá basa': 'assets/products/ca_basa.jpg',
  'Tôm tươi': 'assets/products/tom_tuoi.jpg',
  'Cải thảo': 'assets/products/cai_thao.jpg',
  'Cần tây': 'assets/products/can_tay.jpg',
  'Bí xanh': 'assets/products/bi_xanh.jpg',
  'Cà tím': 'assets/products/ca_tim.jpg',
  'Mì gói': 'assets/products/mi_goi.jpg',
};

/// Trả về asset path cho sản phẩm. Map theo tên; không có thì dùng assets/products/default.jpg.
/// Khi thêm file ảnh (vd. tao_my.jpg) vào assets/products/, ảnh sẽ hiển thị đúng theo tên.
String productImageAsset(String name) {
  if (productImages.containsKey(name)) return productImages[name]!;
  for (final entry in productImages.entries) {
    if (name.startsWith(entry.key) || name.contains(entry.key)) {
      return entry.value;
    }
  }
  return kDefaultProductImage;
}

bool _isNetworkImageUrl(String path) =>
    path.startsWith('http://') || path.startsWith('https://');

/// Local asset or HTTPS [imageUrl] from backend.
Widget _productImageForPath(
  String path, {
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  BoxFit fit = BoxFit.cover,
}) {
  if (_isNetworkImageUrl(path)) {
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (_, __, ___) => Container(
        color: _kPrimaryLight,
        child: const Icon(
          Icons.inventory_2_rounded,
          size: 40,
          color: _kPrimary,
        ),
      ),
    );
  }
  return Image.asset(
    path,
    width: width,
    height: height,
    fit: fit,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: (_, __, ___) => Container(
      color: _kPrimaryLight,
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 40,
        color: _kPrimary,
      ),
    ),
  );
}

/// Trạng thái sản phẩm (chỉ UI)
enum ProductStatus { active, outOfStock, hidden }

/// Mô hình sản phẩm (chỉ UI)
class _StoreProduct {
  final String name;
  final String description;
  final String price;
  final int stock;
  final int soldCount;
  final ProductStatus status;
  final String? imageUrlOverride;

  const _StoreProduct({
    required this.name,
    this.description = '',
    required this.price,
    required this.stock,
    this.soldCount = 0,
    this.status = ProductStatus.active,
    this.imageUrlOverride,
  });

  /// Badge text: "Còn hàng" | "Sắp hết" | "Hết hàng" theo số lượng.
  String get stockStatusLabel {
    if (status == ProductStatus.hidden) return 'Ẩn';
    if (stock == 0) return 'Hết hàng';
    return stock > _kLowStockMax ? 'Còn hàng' : 'Sắp hết';
  }
  String get stockLabel => stock > 0 ? 'Còn $stock' : 'Hết hàng';

  /// Đường dẫn asset ảnh sản phẩm; dùng imageUrlOverride nếu có, không thì map theo tên, fallback default.
  String get imageAssetPath => imageUrlOverride ?? productImageAsset(name);
  bool get isLowStock => stock > 0 && stock <= _kLowStockMax;
  bool get isVeryLowStock => stock > 0 && stock <= 8;
}

String _formatPrice(double? v) {
  if (v == null) return '0đ';
  return '${NumberFormat('#,###', 'vi').format(v.round())}đ';
}

_StoreProduct _fromProductModel(ProductModel m, int displayStock) {
  final st = (m.status ?? '').toUpperCase();
  ProductStatus status;
  if (st == 'HIDDEN') {
    status = ProductStatus.hidden;
  } else if (st == 'OUT_OF_STOCK' || displayStock == 0) {
    status = ProductStatus.outOfStock;
  } else {
    status = ProductStatus.active;
  }
  return _StoreProduct(
    name: m.name ?? '',
    description: m.description ?? '',
    price: _formatPrice(m.price),
    stock: displayStock,
    soldCount: 0,
    status: status,
    imageUrlOverride: m.imageUrl,
  );
}

enum _StockFilter { all, inStock, lowStock, outOfStock, hidden }

bool _matchesStockFilter(
  ProductModel p,
  int stock,
  _StockFilter f,
) {
  final st = (p.status ?? '').toUpperCase();
  final isHidden = st == 'HIDDEN';
  final isOutStatus = st == 'OUT_OF_STOCK';
  switch (f) {
    case _StockFilter.inStock:
      if (isHidden) return false;
      if (isOutStatus) return false;
      return stock > _kLowStockMax;
    case _StockFilter.lowStock:
      if (isHidden) return false;
      if (isOutStatus) return false;
      return stock > 0 && stock <= _kLowStockMax;
    case _StockFilter.outOfStock:
      if (isHidden) return false;
      return isOutStatus || stock == 0;
    case _StockFilter.hidden:
      return isHidden;
    case _StockFilter.all:
      return true;
  }
}

List<ProductModel> _applyProductFilter(
  StoreProductsLoaded loaded,
  _StockFilter stockFilter,
  String searchQuery,
) {
  final products = loaded.products;
  final totals = loaded.stockTotals;
  final kept = <ProductModel>[];
  for (var i = 0; i < products.length; i++) {
    final p = products[i];
    final stock = i < totals.length ? totals[i] : (p.stock ?? 0);
    if (!_matchesStockFilter(p, stock, stockFilter)) continue;
    kept.add(p);
  }
  var result = kept;
  final q = searchQuery.trim();
  if (q.isEmpty) return result;
  final qLower = q.toLowerCase();
  return result
      .where(
        (p) =>
            (p.name ?? '').toLowerCase().contains(qLower) ||
            (p.description ?? '').toLowerCase().contains(qLower),
      )
      .toList();
}

int _displayStockFor(StoreProductsLoaded loaded, ProductModel p) {
  final i = loaded.products.indexOf(p);
  if (i < 0) return p.stock ?? 0;
  return i < loaded.stockTotals.length ? loaded.stockTotals[i] : (p.stock ?? 0);
}

class StoreProductsScreen extends StatefulWidget {
  final String token;

  const StoreProductsScreen({super.key, required this.token});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _debouncedQuery = '';
  Timer? _debounceTimer;
  _StockFilter _stockFilter = _StockFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    context.read<StoreProductsBloc>().add(LoadStoreProducts(token: widget.token));
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: _kSearchDebounceMs),
      () {
        if (mounted) setState(() => _debouncedQuery = text);
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  static double _parsePrice(String text) {
    final s = text.replaceAll(RegExp(r'[^\d]'), '');
    return (int.tryParse(s) ?? 0).toDouble();
  }

  void _showAddProductModal(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddProductSheet(
        nameController: nameController,
        descController: descController,
        priceController: priceController,
        qtyController: qtyController,
        onSave: null,
        onSaveToApi:
            (
              name,
              description,
              price,
              stock,
              status, {
              Uint8List? imageBytes,
              String? imageFilename,
            }) {
              final effectiveStock = status == ProductStatus.outOfStock
                  ? 0
                  : stock;
              final params = StoreCreateProductParams(
                name: name,
                description: description.isEmpty ? null : description,
                price: price,
                stock: effectiveStock,
                imageUrl: null,
                markHiddenAfterCreate: status == ProductStatus.hidden,
                pendingImageBytes: imageBytes?.toList(),
                pendingImageFilename: imageFilename,
              );
              context.read<StoreProductsBloc>().add(
                CreateStoreProduct(token: widget.token, params: params),
              );
            },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showEditProduct(BuildContext context, ProductModel productModel) {
    final blocState = context.read<StoreProductsBloc>().state;
    final loaded = blocState is StoreProductsLoaded ? blocState : null;
    final stock = loaded != null
        ? _displayStockFor(loaded, productModel)
        : (productModel.stock ?? 0);
    final p = _fromProductModel(productModel, stock);
    final nameController = TextEditingController(text: p.name);
    final descController = TextEditingController(text: p.description);
    final priceController = TextEditingController(text: p.price);
    final stockController = TextEditingController(text: '$stock');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProductSheet(
        product: p,
        productId: productModel.id,
        nameController: nameController,
        descController: descController,
        priceController: priceController,
        stockController: stockController,
        onSave: null,
        onSaveToApi: ({
          required String name,
          required String description,
          Uint8List? newImageBytes,
          String? newImageFilename,
        }) {
          if (productModel.id == null || productModel.id!.isEmpty) return;
          final parsedPrice = _parsePrice(priceController.text);
          final initPrice = productModel.price;
          final priceChanged = initPrice != null &&
              (parsedPrice - initPrice).abs() > 0.001;
          final stockParsed = int.tryParse(stockController.text.trim());
          final stockChanged =
              stockParsed != null && stockParsed != stock;
          context.read<StoreProductsBloc>().add(
            SaveStoreProductEdit(
              token: widget.token,
              productId: productModel.id!,
              name: name,
              description: description,
              newImageBytes: newImageBytes?.toList(),
              newImageFilename: newImageFilename,
            ),
          );
          if (priceChanged || stockChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Giá và số lượng không thể cập nhật từ ứng dụng: máy chủ hiện chưa hỗ trợ thay đổi tồn kho/giá sau khi tạo sản phẩm.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<StoreProductsBloc, StoreProductsState>(
      listenWhen: (prev, curr) =>
          curr is StoreProductsLoaded && curr.successMessage != null,
      listener: (context, state) {
        if (state is StoreProductsLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: _kPrimary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<StoreProductsBloc>().add(ClearStoreProductsMessage());
        }
      },
      child: BlocListener<StoreProductsBloc, StoreProductsState>(
      listenWhen: (prev, curr) => curr is StoreProductsError,
      listener: (context, state) {
        if (state is StoreProductsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _kSurface,
        appBar: AppBar(
          title: Text(
            'Quản lý sản phẩm',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          foregroundColor: const Color(0xFF1A1A1A),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kPaddingLarge,
                    kPaddingMedium,
                    kPaddingLarge,
                    kCardPadding,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm sản phẩm...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: _kPrimary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _FilterChip(
                              label: 'Tất cả',
                              selected: _stockFilter == _StockFilter.all,
                              onTap: () => setState(
                                () => _stockFilter = _StockFilter.all,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Còn hàng',
                              selected: _stockFilter == _StockFilter.inStock,
                              onTap: () => setState(
                                () => _stockFilter = _StockFilter.inStock,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Sắp hết',
                              selected: _stockFilter == _StockFilter.lowStock,
                              onTap: () => setState(
                                () => _stockFilter = _StockFilter.lowStock,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Hết hàng',
                              selected: _stockFilter == _StockFilter.outOfStock,
                              onTap: () => setState(
                                () => _stockFilter = _StockFilter.outOfStock,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Ẩn',
                              selected: _stockFilter == _StockFilter.hidden,
                              onTap: () => setState(
                                () => _stockFilter = _StockFilter.hidden,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<StoreProductsBloc, StoreProductsState>(
                    builder: (context, state) {
                      final isLoading = state is StoreProductsLoading;
                      if (isLoading) {
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            kPaddingLarge,
                            0,
                            kPaddingLarge,
                            100,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: kCardPadding,
                                crossAxisSpacing: kCardPadding,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: 12,
                          itemBuilder: (context, index) =>
                              const _ProductCardSkeleton(),
                        );
                      }
                      if (state is! StoreProductsLoaded) {
                        return const Center(child: Text('Chưa có dữ liệu'));
                      }
                      final loaded = state;
                      final filteredModels = _applyProductFilter(
                        loaded,
                        _stockFilter,
                        _debouncedQuery,
                      );
                      final filteredDisplay = filteredModels
                          .map(
                            (m) => _fromProductModel(
                              m,
                              _displayStockFor(loaded, m),
                            ),
                          )
                          .toList();
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          kPaddingLarge,
                          0,
                          kPaddingLarge,
                          100,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: kCardPadding,
                              crossAxisSpacing: kCardPadding,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: filteredDisplay.length,
                        itemBuilder: (context, index) {
                          final productModel = filteredModels[index];
                          final p = filteredDisplay[index];
                          return _ProductCard(
                            product: p,
                            onTap: () =>
                                _showEditProduct(context, productModel),
                            onToggleVisibility: productModel.id == null
                                ? null
                                : () {
                                    context.read<StoreProductsBloc>().add(
                                      ToggleProductVisibility(
                                        widget.token,
                                        productModel.id!,
                                      ),
                                    );
                                  },
                            onMarkOutOfStock: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Máy chủ hiện chưa hỗ trợ cập nhật tồn kho từ thao tác này.',
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Material(
          elevation: 2,
          shadowColor: _kPrimary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          color: _kPrimary,
          child: InkWell(
            onTap: () => _showAddProductModal(context),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 24, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Thêm sản phẩm',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Lightweight skeleton for product card (static grey boxes).
const Color _kSkeletonColor = Color(0xFFE8E8E8);

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: _kSkeletonColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(kRadiusLarge),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(kCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: _kSkeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: _kSkeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Màu badge tồn kho: >20 xanh (Còn hàng), 1–20 cam (Sắp hết), 0 đỏ (Hết hàng).
Color _stockBadgeColor(_StoreProduct p) {
  if (p.status == ProductStatus.hidden) return Colors.grey;
  if (p.stock == 0) return const Color(0xFFD32F2F); // Hết hàng — red
  if (p.stock > _kLowStockMax) return _kPrimary; // Còn hàng — green
  return const Color(0xFFF57C00); // Sắp hết (1–20) — orange
}

/// Nhãn trạng thái sản phẩm (chỉ UI)
String _statusLabel(ProductStatus s) {
  switch (s) {
    case ProductStatus.active:
      return 'Đang bán';
    case ProductStatus.outOfStock:
      return 'Hết hàng';
    case ProductStatus.hidden:
      return 'Ẩn';
  }
}

/// Thẻ sản phẩm — ảnh, tên, giá, đã bán, badge tồn kho, trạng thái, hover mượt, quick edit/hide/hết hàng
class _ProductCard extends StatefulWidget {
  final _StoreProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onMarkOutOfStock;

  const _ProductCard({
    required this.product,
    this.onTap,
    this.onToggleVisibility,
    this.onMarkOutOfStock,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hover = false;
  bool _longPressActive = false;

  bool get _showQuickActions => _hover || _longPressActive;

  void _hideQuickActions() {
    if (_longPressActive && mounted) setState(() => _longPressActive = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final badgeColor = _stockBadgeColor(p);
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.diagonal3Values(
        _hover ? 1.015 : 1.0,
        _hover ? 1.015 : 1.0,
        1.0,
      ),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: _hover
              ? _kPrimary.withValues(alpha: 0.25)
              : Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: _hover ? 12 : 8,
            offset: Offset(0, _hover ? 5 : 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _kImageHeight,
            width: double.infinity,
            child: GestureDetector(
              onLongPress: kIsWeb
                  ? null
                  : () => setState(() => _longPressActive = true),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kRadiusLarge),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedScale(
                      scale: _hover ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      child: _productImageForPath(
                        p.imageAssetPath,
                        width: _kImageWidth,
                        height: _kImageHeight,
                        cacheWidth: _kCacheWidth,
                        cacheHeight: _kCacheHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(kRadiusSmall),
                              border: Border.all(
                                color: badgeColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              p.stockStatusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(kRadiusSmall),
                        ),
                        child: Text(
                          _statusLabel(p.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    if (_showQuickActions &&
                        (widget.onTap != null ||
                            widget.onToggleVisibility != null))
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _hideQuickActions,
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: _showQuickActions ? 1 : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(kRadiusLarge),
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.onTap != null)
                                      _QuickActionButton(
                                        icon: Icons.edit_rounded,
                                        tooltip: 'Sửa',
                                        color: _kPrimary,
                                        onTap: () {
                                          _hideQuickActions();
                                          widget.onTap!();
                                        },
                                      ),
                                    if (widget.onTap != null &&
                                        widget.onToggleVisibility != null)
                                      const SizedBox(width: 8),
                                    if (widget.onTap != null)
                                      _QuickActionButton(
                                        icon: Icons.info_outline_rounded,
                                        tooltip: 'Xem chi tiết',
                                        color: const Color(0xFF1976D2),
                                        onTap: () {
                                          _hideQuickActions();
                                          widget.onTap!();
                                        },
                                      ),
                                    if (widget.onToggleVisibility != null)
                                      const SizedBox(width: 8),
                                    if (widget.onToggleVisibility != null &&
                                        p.status != ProductStatus.hidden)
                                      _QuickActionButton(
                                        icon: Icons.visibility_off_rounded,
                                        tooltip: 'Ẩn',
                                        color: Colors.grey.shade700,
                                        onTap: () {
                                          _hideQuickActions();
                                          widget.onToggleVisibility!();
                                        },
                                      ),
                                    if (widget.onToggleVisibility != null &&
                                        p.status == ProductStatus.hidden)
                                      _QuickActionButton(
                                        icon: Icons.visibility_rounded,
                                        tooltip: 'Bỏ ẩn',
                                        color: Colors.grey.shade700,
                                        onTap: () {
                                          _hideQuickActions();
                                          widget.onToggleVisibility!();
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.onMarkOutOfStock != null &&
                        p.status == ProductStatus.active &&
                        p.stock > 0 &&
                        _showQuickActions)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: Center(
                          child: Material(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(kRadiusSmall),
                            child: InkWell(
                              onTap: () {
                                _hideQuickActions();
                                widget.onMarkOutOfStock!();
                              },
                              borderRadius: BorderRadius.circular(kRadiusSmall),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.remove_circle_outline_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Hết hàng',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(kCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (p.soldCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Đã bán: ${p.soldCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  p.price,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: card,
      );
    }

    return ScaleOnTap(onTap: widget.onTap, child: card);
  }
}

/// Nút quick action nhỏ (icon tròn) — dùng Tooltip trên web.
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final material = Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
    if (kIsWeb) {
      return Tooltip(message: tooltip, child: material);
    }
    return material;
  }
}

/// Chip lọc (Tất cả / Còn hàng / ...)
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: selected
                ? null
                : [
                    const BoxShadow(
                      color: _kCardShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip trạng thái trong modal (Đang bán / Hết hàng / Ẩn)
class _StatusChip extends StatelessWidget {
  final String label;
  final ProductStatus value;
  final ProductStatus current;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kPrimaryLight : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(kRadiusSmall),
            border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? _kPrimary : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet thêm sản phẩm mới — ảnh, tên, mô tả, giá, số lượng, trạng thái
class _AddProductSheet extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final TextEditingController priceController;
  final TextEditingController qtyController;
  final void Function(_StoreProduct product)? onSave;
  final void Function(
    String name,
    String description,
    double price,
    int stock,
    ProductStatus status, {
    Uint8List? imageBytes,
    String? imageFilename,
  })?
  onSaveToApi;
  final VoidCallback onCancel;

  const _AddProductSheet({
    required this.nameController,
    required this.descController,
    required this.priceController,
    required this.qtyController,
    this.onSave,
    this.onSaveToApi,
    required this.onCancel,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  ProductStatus _selectedStatus = ProductStatus.active;
  bool _imagePicked = false;
  Uint8List? _pickedBytes;
  String? _pickedFilename;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kRadiusLarge + 4),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              kPaddingLarge,
              kPaddingMedium,
              kPaddingLarge,
              kPaddingLarge + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: kSectionSpacing),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Thêm sản phẩm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: kSectionSpacing),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final x = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1600,
                      imageQuality: 85,
                    );
                    if (x == null) return;
                    final bytes = await x.readAsBytes();
                    if (!mounted) return;
                    setState(() {
                      _pickedBytes = bytes;
                      _pickedFilename =
                          x.name.isNotEmpty ? x.name : 'san-pham.jpg';
                      _imagePicked = true;
                    });
                  },
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _kPrimaryLight,
                      borderRadius: BorderRadius.circular(kRadiusMedium),
                      border: Border.all(
                        color: _kPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _pickedBytes != null
                        ? Image.memory(
                            _pickedBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _imagePicked
                                    ? Icons.check_circle_rounded
                                    : Icons.add_photo_alternate_rounded,
                                size: 48,
                                color: _kPrimary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _imagePicked
                                    ? 'Đã chọn ảnh'
                                    : 'Tải ảnh lên',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: kSectionSpacing),
                TextField(
                  controller: widget.nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên sản phẩm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    prefixIcon: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: kCardPadding),
                TextField(
                  controller: widget.descController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: kCardPadding),
                TextField(
                  controller: widget.priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VNĐ)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: kCardPadding),
                TextField(
                  controller: widget.qtyController,
                  decoration: InputDecoration(
                    labelText: 'Số lượng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    prefixIcon: const Icon(Icons.inventory_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: kSectionSpacing),
                Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusChip(
                      label: 'Đang bán',
                      value: ProductStatus.active,
                      current: _selectedStatus,
                      onTap: () => setState(
                        () => _selectedStatus = ProductStatus.active,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Hết hàng',
                      value: ProductStatus.outOfStock,
                      current: _selectedStatus,
                      onTap: () => setState(
                        () => _selectedStatus = ProductStatus.outOfStock,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Ẩn',
                      value: ProductStatus.hidden,
                      current: _selectedStatus,
                      onTap: () => setState(
                        () => _selectedStatus = ProductStatus.hidden,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSectionSpacing),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMedium),
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMedium),
                          ),
                        ),
                        onPressed: _saving
                            ? null
                            : () async {
                                final name = widget.nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập tên sản phẩm',
                                      ),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                final price =
                                    _StoreProductsScreenState._parsePrice(
                                      widget.priceController.text,
                                    );
                                if (price <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Giá phải lớn hơn 0'),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _saving = true);
                                try {
                                  if (widget.onSaveToApi != null) {
                                    final stock =
                                        (int.tryParse(
                                                  widget.qtyController.text,
                                                ) ??
                                                0)
                                            .clamp(0, 9999);
                                    widget.onSaveToApi!(
                                      name,
                                      widget.descController.text.trim(),
                                      price,
                                      stock,
                                      _selectedStatus,
                                      imageBytes: _pickedBytes,
                                      imageFilename: _pickedFilename,
                                    );
                                    if (mounted) Navigator.pop(context);
                                  } else if (widget.onSave != null) {
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                    if (!mounted) return;
                                    widget.onSave!(
                                      _StoreProduct(
                                        name: name,
                                        description: widget.descController.text
                                            .trim(),
                                        price:
                                            widget.priceController.text
                                                .trim()
                                                .isEmpty
                                            ? '0đ'
                                            : widget.priceController.text,
                                        stock:
                                            (int.tryParse(
                                                      widget.qtyController.text,
                                                    ) ??
                                                    0)
                                                .clamp(0, 9999),
                                        soldCount: 0,
                                        status: _selectedStatus,
                                        imageUrlOverride: null,
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => _saving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không thể thêm sản phẩm. Vui lòng thử lại.',
                                        ),
                                        backgroundColor: Color(0xFFD32F2F),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Thêm sản phẩm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet chỉnh sửa sản phẩm — ảnh, tên, mô tả, giá, số lượng, trạng thái
class _EditProductSheet extends StatefulWidget {
  final _StoreProduct product;
  final String? productId;
  final TextEditingController nameController;
  final TextEditingController descController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final void Function(_StoreProduct updated)? onSave;
  final void Function({
    required String name,
    required String description,
    Uint8List? newImageBytes,
    String? newImageFilename,
  })?
  onSaveToApi;
  final VoidCallback onCancel;

  const _EditProductSheet({
    required this.product,
    this.productId,
    required this.nameController,
    required this.descController,
    required this.priceController,
    required this.stockController,
    this.onSave,
    this.onSaveToApi,
    required this.onCancel,
  });

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  late ProductStatus _selectedStatus;
  Uint8List? _pickedImageBytes;
  String? _pickedImageFilename;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.product.status;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kRadiusLarge + 4),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              kPaddingLarge,
              kPaddingMedium,
              kPaddingLarge,
              kPaddingLarge + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: kSectionSpacing),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Chỉnh sửa sản phẩm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: kSectionSpacing),
                ClipRRect(
                  borderRadius: BorderRadius.circular(kRadiusMedium),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: _pickedImageBytes != null
                            ? Image.memory(
                                _pickedImageBytes!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : _productImageForPath(
                                p.imageUrlOverride ?? productImageAsset(p.name),
                                height: 160,
                                width: double.infinity,
                                cacheWidth: _kCacheWidth,
                                cacheHeight: 320,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(kRadiusSmall),
                          child: InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final x = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1600,
                                imageQuality: 85,
                              );
                              if (x == null) return;
                              final bytes = await x.readAsBytes();
                              if (!mounted) return;
                              setState(() {
                                _pickedImageBytes = bytes;
                                _pickedImageFilename = x.name.isNotEmpty
                                    ? x.name
                                    : 'san-pham.jpg';
                              });
                            },
                            borderRadius: BorderRadius.circular(kRadiusSmall),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_camera_rounded,
                                    size: 18,
                                    color: _kPrimary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Đổi ảnh',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kSectionSpacing),
                TextField(
                  controller: widget.nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên sản phẩm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    prefixIcon: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: kCardPadding),
                TextField(
                  controller: widget.descController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: kCardPadding),
                TextField(
                  controller: widget.priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VNĐ)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: kCardPadding),
                TextField(
                  controller: widget.stockController,
                  decoration: InputDecoration(
                    labelText: 'Số lượng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    prefixIcon: const Icon(Icons.inventory_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: kSectionSpacing),
                Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusChip(
                      label: 'Đang bán',
                      value: ProductStatus.active,
                      current: _selectedStatus,
                      onTap: () => setState(
                        () => _selectedStatus = ProductStatus.active,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Hết hàng',
                      value: ProductStatus.outOfStock,
                      current: _selectedStatus,
                      onTap: () => setState(
                        () => _selectedStatus = ProductStatus.outOfStock,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Ẩn',
                      value: ProductStatus.hidden,
                      current: _selectedStatus,
                      onTap: () => setState(
                        () => _selectedStatus = ProductStatus.hidden,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSectionSpacing),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMedium),
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMedium),
                          ),
                        ),
                        onPressed: _saving
                            ? null
                            : () async {
                                if (widget.onSaveToApi != null &&
                                    widget.productId != null) {
                                  final name =
                                      widget.nameController.text
                                          .trim()
                                          .isEmpty
                                      ? p.name
                                      : widget.nameController.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Vui lòng nhập tên sản phẩm',
                                        ),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => _saving = true);
                                  widget.onSaveToApi!(
                                    name: name,
                                    description:
                                        widget.descController.text.trim(),
                                    newImageBytes: _pickedImageBytes,
                                    newImageFilename: _pickedImageFilename,
                                  );
                                  if (_selectedStatus != widget.product.status) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Trạng thái hiển thị không thể cập nhật từ màn sửa; vui lòng dùng thao tác trên danh sách sản phẩm.',
                                          ),
                                          backgroundColor: Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                } else if (widget.onSave != null) {
                                  setState(() => _saving = true);
                                  try {
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                    if (!mounted) return;
                                    final name =
                                        widget.nameController.text
                                            .trim()
                                            .isEmpty
                                        ? p.name
                                        : widget.nameController.text.trim();
                                    final price =
                                        widget.priceController.text
                                            .trim()
                                            .isEmpty
                                        ? p.price
                                        : widget.priceController.text;
                                    final stock =
                                        int.tryParse(
                                          widget.stockController.text,
                                        ) ??
                                        p.stock;
                                    widget.onSave!(
                                      _StoreProduct(
                                        name: name,
                                        description: widget.descController.text
                                            .trim(),
                                        price: price,
                                        stock: stock.clamp(0, 9999),
                                        soldCount: widget.product.soldCount,
                                        status: _selectedStatus,
                                        imageUrlOverride:
                                            p.imageUrlOverride,
                                      ),
                                    );
                                  } catch (_) {
                                    if (mounted) {
                                      setState(() => _saving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Không thể cập nhật sản phẩm. Vui lòng thử lại.',
                                          ),
                                          backgroundColor: Color(0xFFD32F2F),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
