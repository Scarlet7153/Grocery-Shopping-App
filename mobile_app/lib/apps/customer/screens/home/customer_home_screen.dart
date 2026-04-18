import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../core/theme/customer_theme.dart';
import '../../../../features/customer/home/data/product_model.dart';
import '../../bloc/customer_home_bloc.dart';
import '../../services/customer_current_location_service.dart';
import '../../shared/customer_product_list_card.dart';
import '../../shared/customer_state_view.dart';
import '../../shared/variant_selection_sheet.dart';
import '../../utils/customer_l10n.dart';
import '../cart/customer_cart_screen.dart';
import '../chat/customer_chat_list_screen.dart';
import '../orders/customer_orders_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../profile/recipient_info_screen.dart';
import 'all_products_screen.dart';
import 'home_app_bar.dart';
import 'product_detail_screen.dart';
import 'product_search_screen.dart';
import 'store_products_screen.dart';
import 'widgets/home_header.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerHomeBloc()..add(LoadHomeEvent()),
      child: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;
  int _homeLocationVersion = 0;

  @override
  Widget build(BuildContext context) {
    Widget body;
    PreferredSizeWidget? appBar;

    if (_currentIndex == 0) {
      body = _HomeView(key: ValueKey('home-$_homeLocationVersion'));
      final name =
          (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
              ? context.tr(vi: 'Khách hàng', en: 'Customer')
              : AuthSession.fullName!;
      final location = AuthSession.displayLocation;
      appBar = CustomerHomeHeader(
        name: name,
        location: location,
        avatarUrl: AuthSession.avatarUrl,
        isUsingCurrentLocation: AuthSession.useCurrentLocation,
        onUseCurrentLocationTap: () async {
          final result = await CustomerCurrentLocationService.instance
              .initializeCurrentLocation();
          if (!mounted) return;

          if (result == CustomerLocationStatus.serviceDisabled) {
            await _showLocationServiceDialog();
          } else if (result == CustomerLocationStatus.permissionDeniedForever) {
            await _showAppSettingsDialog();
          }

          context.read<CustomerHomeBloc>().add(RefreshHomeEvent());
          setState(() {
            _homeLocationVersion++;
          });
        },
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecipientInfoScreen()),
          );
          if (!mounted) return;
          context.read<CustomerHomeBloc>().add(RefreshHomeEvent());
          setState(() {
            _homeLocationVersion++;
          });
        },
      );
    } else if (_currentIndex == 1) {
      body = const CustomerCartScreen();
      appBar = AppBar(title: Text(context.tr(vi: 'Giỏ hàng', en: 'Cart')));
    } else if (_currentIndex == 2) {
      body = const CustomerOrdersScreen();
      appBar = AppBar(title: Text(context.tr(vi: 'Đơn hàng', en: 'Orders')));
    } else if (_currentIndex == 3) {
      body = const CustomerChatListScreen();
      appBar = AppBar(title: Text(context.tr(vi: 'Chat', en: 'Chat')));
    } else {
      body = const CustomerProfileScreen();
      appBar = AppBar(title: Text(context.tr(vi: 'Hồ sơ', en: 'Profile')));
    }

    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: HomeBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
        },
      ),
      body: body,
    );
  }

  Future<void> _showLocationServiceDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vị trí cần được bật'),
          content: const Text(
            'Ứng dụng cần bật dịch vụ vị trí để xác định vị trí hiện tại. Vui lòng bật định vị và thử lại.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Mở cài đặt'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAppSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quyền vị trí bị chặn'),
          content: const Text(
            'Quyền truy cập vị trí đã bị từ chối vĩnh viễn. Vui lòng mở cài đặt app và bật lại.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Mở cài đặt'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({super.key});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedCategory;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
    final pageBg = scheme.surfaceContainerLowest;
    final cardBg = scheme.surface;

    return BlocBuilder<CustomerHomeBloc, CustomerHomeState>(
      builder: (context, state) {
        if (state is CustomerHomeLoading) {
          return CustomerStateView.loading(compact: true);
        }

        if (state is CustomerHomeLoaded) {
          final storeAddressByName = <String, String>{
            for (final store in state.featuredStores)
              store.storeName.trim().toLowerCase(): store.address,
          };

          final filteredProducts =
              (_selectedCategory == null || _selectedCategory!.trim().isEmpty)
                  ? state.products
                  : state.products
                      .where(
                        (p) =>
                            p.categoryName.trim().toLowerCase() ==
                            _selectedCategory!.trim().toLowerCase(),
                      )
                      .toList();

          return Container(
            color: pageBg,
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<CustomerHomeBloc>().add(RefreshHomeEvent());
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () {
                            context.read<CustomerHomeBloc>().add(
                                  SearchProductsEvent(value),
                                );
                          },
                        );
                      },
                      onSubmitted: (value) {
                        final keyword = value.trim();
                        if (keyword.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductSearchScreen(
                              query: keyword,
                              products: state.products,
                            ),
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: context.tr(
                            vi: 'Tìm sản phẩm...', en: 'Search products...'),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            final keyword = _searchController.text.trim();
                            if (keyword.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductSearchScreen(
                                  query: keyword,
                                  products: state.products,
                                ),
                              ),
                            );
                          },
                        ),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (state.searchSuggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.searchSuggestions.length > 5
                              ? 5
                              : state.searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final product = state.searchSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.search),
                              title: Text(product.name),
                              subtitle: product.storeName.isEmpty
                                  ? null
                                  : Text(product.storeName),
                              onTap: () {
                                _searchController.text = product.name;
                                _searchController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _searchController.text.length,
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductSearchScreen(
                                      query: product.name,
                                      products: state.products,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  _sectionHeader(context.tr(vi: 'Danh mục', en: 'Categories')),
                  SizedBox(
                    height: 90,
                    child: state.categories.isEmpty
                        ? Center(
                            child: Text(context.tr(
                                vi: 'Chưa có danh mục',
                                en: 'No categories yet')),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: state.categories.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _categoryItem(
                                  context,
                                  context.tr(vi: 'Tất cả', en: 'All'),
                                  selected: _selectedCategory == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = null;
                                    });
                                  },
                                );
                              }
                              final category = state.categories[index - 1];
                              final isSelected =
                                  _selectedCategory?.trim().toLowerCase() ==
                                      category.name.trim().toLowerCase();
                              return _categoryItem(
                                context,
                                category.name,
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category.name;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  _sectionHeader(context.tr(
                      vi: 'Cửa hàng nổi bật', en: 'Featured stores')),
                  SizedBox(
                    height: 160,
                    child: state.featuredStores.isEmpty
                        ? Center(
                            child: Text(
                              context.tr(
                                  vi: 'Chưa có cửa hàng nổi bật',
                                  en: 'No featured stores yet'),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: state.featuredStores.length,
                            itemBuilder: (context, index) {
                              final store = state.featuredStores[index];
                              return _storeCard(
                                context: context,
                                name: store.storeName,
                                address: store.address,
                                isOpen: store.isOpen,
                                averageRating: store.averageRating,
                                totalReviews: store.totalReviews,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoreProductsScreen(
                                        store: store,
                                        initialProducts: state.products,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  _sectionHeader(
                    context.tr(vi: 'Sản phẩm phổ biến', en: 'Popular products'),
                    onViewAll: () async {
                      final selectedCategory = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllProductsScreen(
                            initialProducts: state.products,
                            initialCategories:
                                state.categories.map((c) => c.name).toList(),
                            initialSelectedCategory: _selectedCategory,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {
                        _selectedCategory = (selectedCategory == null ||
                                selectedCategory.trim().isEmpty)
                            ? null
                            : selectedCategory;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              _selectedCategory == null
                                  ? context.tr(
                                      vi: 'Chưa có sản phẩm',
                                      en: 'No products yet')
                                  : context.tr(
                                      vi: 'Không có sản phẩm cho danh mục "$_selectedCategory"',
                                      en: 'No products for category "$_selectedCategory"',
                                    ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];

                              return CustomerProductListCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                        product: product,
                                      ),
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
                                customerLongitude:
                                    AuthSession.selectedLongitude,
                                storeAddress: storeAddressByName[
                                    product.storeName.trim().toLowerCase()],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }

        return CustomerStateView.error(
          compact: true,
          onAction: () =>
              context.read<CustomerHomeBloc>().add(RefreshHomeEvent()),
        );
      },
    );
  }
}

Widget _sectionHeader(String text, {VoidCallback? onViewAll}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Builder(
              builder: (context) =>
                  Text(context.tr(vi: 'Xem tất cả', en: 'View all')),
            ),
          ),
      ],
    ),
  );
}

Widget _categoryItem(
  BuildContext context,
  String name, {
  bool selected = false,
  VoidCallback? onTap,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 96,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color:
            selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? scheme.primary : Colors.transparent,
          width: selected ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.1), blurRadius: 6),
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
                  : CustomerTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _categoryIcon(name),
              size: 18,
              color: selected ? scheme.primary : CustomerTheme.primaryColor,
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

Widget _storeCard({
  required BuildContext context,
  required String name,
  required String address,
  required bool isOpen,
  double? averageRating,
  int? totalReviews,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CustomerTheme.primaryColor,
                    CustomerTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Colors.green.withValues(alpha: 0.9)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOpen
                            ? context.tr(vi: 'Mở', en: 'Open')
                            : context.tr(vi: 'Đóng', en: 'Closed'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (averageRating != null && totalReviews != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($totalReviews)',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
