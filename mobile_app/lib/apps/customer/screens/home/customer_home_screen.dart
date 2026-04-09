import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../core/format/formatters.dart';
import '../../bloc/customer_home_bloc.dart';
import '../cart/customer_cart_screen.dart';
import '../orders/customer_orders_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../profile/recipient_info_screen.dart';
import 'home_app_bar.dart';
import 'product_search_screen.dart';
import 'product_detail_screen.dart';
import 'widgets/home_header.dart';

const Color _primaryBlue = Color(0xFF2F80ED);
const Color _softBg = Color(0xFFF6F8FB);

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

  @override
  Widget build(BuildContext context) {
    Widget body;
    PreferredSizeWidget? appBar;

    if (_currentIndex == 0) {
      body = const _HomeView();
      final name =
          (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
          ? 'Kh\u00e1ch h\u00e0ng'
          : AuthSession.fullName!;
      final location =
          (AuthSession.address == null || AuthSession.address!.isEmpty)
          ? 'Ch\u01b0a c\u00f3 \u0111\u1ecba ch\u1ec9'
          : AuthSession.address!;
      appBar = CustomerHomeHeader(
        name: name,
        location: location,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecipientInfoScreen()),
          );
          if (mounted) setState(() {});
        },
      );
    } else if (_currentIndex == 1) {
      body = const CustomerCartScreen();
      appBar = AppBar(title: const Text('Gi\u1ecf h\u00e0ng'));
    } else if (_currentIndex == 2) {
      body = const CustomerOrdersScreen();
      appBar = AppBar(title: const Text('\u0110\u01a1n h\u00e0ng'));
    } else {
      body = const CustomerProfileScreen();
      appBar = AppBar(title: const Text('H\u1ed3 s\u01a1'));
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
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerHomeBloc, CustomerHomeState>(
      builder: (context, state) {
        if (state is CustomerHomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomerHomeLoaded) {
          return Container(
            color: _softBg,
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
                        hintText: 'T\u00ecm s\u1ea3n ph\u1ea9m... ',
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
                        fillColor: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -30,
                            child: Icon(
                              Icons.shopping_basket,
                              size: 140,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '\u0110i ch\u1ee3 nhanh',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '\u01afu \u0111\u00e3i m\u1ed7i ng\u00e0y cho kh\u00e1ch h\u00e0ng m\u1edbi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _sectionHeader('Danh m\u1ee5c'),
                  SizedBox(
                    height: 90,
                    child: state.categories.isEmpty
                        ? const Center(
                            child: Text('Ch\u01b0a c\u00f3 danh m\u1ee5c'),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: state.categories.length,
                            itemBuilder: (context, index) {
                              final category = state.categories[index];
                              return _categoryItem(category.name);
                            },
                          ),
                  ),
                  _sectionHeader('C\u1eeda h\u00e0ng n\u1ed5i b\u1eadt'),
                  SizedBox(
                    height: 140,
                    child: state.featuredStores.isEmpty
                        ? const Center(
                            child: Text(
                              'Ch\u01b0a c\u00f3 c\u1eeda h\u00e0ng n\u1ed5i b\u1eadt',
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: state.featuredStores.length,
                            itemBuilder: (context, index) {
                              final store = state.featuredStores[index];
                              return _storeCard(
                                name: store.storeName,
                                address: store.address,
                                isOpen: store.isOpen,
                              );
                            },
                          ),
                  ),
                  _sectionHeader('S\u1ea3n ph\u1ea9m ph\u1ed5 bi\u1ebfn'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: state.products.isEmpty
                        ? const Center(
                            child: Text('Ch\u01b0a c\u00f3 s\u1ea3n ph\u1ea9m'),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemBuilder: (context, index) {
                              final product = state.products[index];

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                          child: product.imageUrl.isEmpty
                                              ? Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                  ),
                                                )
                                              : (product.imageUrl.startsWith(
                                                  'assets/',
                                                ))
                                              ? Image.asset(
                                                  product.imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                )
                                              : Image.network(
                                                  product.imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorBuilder:
                                                      (context, error, stack) {
                                                        return Container(
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Icon(
                                                            Icons.image,
                                                          ),
                                                        );
                                                      },
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _primaryBlue
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    formatVnd(
                                                      product.displayPrice,
                                                    ),
                                                    style: const TextStyle(
                                                      color: _primaryBlue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    CartSession.addProduct(
                                                      product,
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        content: Text(
                                                          '\u0110\u00e3 th\u00eam v\u00e0o gi\u1ecf h\u00e0ng',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: _primaryBlue,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.add_shopping_cart,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
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
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}

Widget _sectionHeader(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Xem t\u1ea5t c\u1ea3')),
      ],
    ),
  );
}

Widget _categoryItem(String name) {
  return Container(
    width: 86,
    margin: const EdgeInsets.only(right: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_categoryIcon(name), size: 18, color: _primaryBlue),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
  required String name,
  required String address,
  required bool isOpen,
}) {
  return Container(
    width: 240,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store, size: 18, color: _primaryBlue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          address,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOpen ? 'M\u1edf' : '\u0110\u00f3ng',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    ),
  );
}
