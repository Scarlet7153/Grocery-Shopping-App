import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../features/customer/home/data/home_api.dart';
import '../../../../features/customer/home/data/product_model.dart';
import '../../shared/customer_product_list_card.dart';
import '../../shared/customer_state_view.dart';
import '../../shared/variant_selection_sheet.dart';
import '../../utils/customer_l10n.dart';
import 'product_detail_screen.dart';

const Color _softBg = Color(0xFFF6F8FB);

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({
    super.key,
    required this.query,
    required this.products,
  });

  final String query;
  final List<ProductModel> products;

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final HomeApi _api = HomeApi();
  final Map<String, String> _storeAddressByName = {};

  @override
  void initState() {
    super.initState();
    _loadStoreAddresses();
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

  @override
  Widget build(BuildContext context) {
    final keyword = widget.query.trim();
    final lower = keyword.toLowerCase();
    final results = keyword.isEmpty
        ? <ProductModel>[]
        : widget.products
            .where((p) => p.name.toLowerCase().contains(lower))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          keyword.isEmpty ? context.tr(vi: 'Tìm kiếm', en: 'Search') : keyword,
        ),
      ),
      body: Container(
        color: _softBg,
        child: results.isEmpty
            ? CustomerStateView.empty(
                compact: true,
                title: keyword.isEmpty
                    ? context.tr(
                        vi: 'Nhập từ khóa để bắt đầu tìm',
                        en: 'Enter a keyword to start searching',
                      )
                    : context.tr(
                        vi: 'Không tìm thấy sản phẩm phù hợp',
                        en: 'No matching products found',
                      ),
                message: keyword.isEmpty
                    ? context.tr(
                        vi: 'Hãy nhập tên sản phẩm hoặc cửa hàng bạn muốn mua.',
                        en: 'Type the product or store name you want.',
                      )
                    : context.tr(
                        vi: 'Thử từ khóa khác hoặc quay lại trang chủ để xem gợi ý.',
                        en: 'Try another keyword or go back home for suggestions.',
                      ),
                icon: Icon(
                  keyword.isEmpty ? Icons.search_rounded : Icons.search_off,
                  size: 52,
                  color: Colors.black38,
                ),
                actionLabel: keyword.isEmpty
                    ? context.tr(vi: 'Quay lại', en: 'Go back')
                    : context.tr(vi: 'Thử lại', en: 'Try again'),
                onAction: () => Navigator.of(context).pop(),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final product = results[index];
                  return CustomerProductListCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    customerLatitude: AuthSession.selectedLatitude,
                    customerLongitude: AuthSession.selectedLongitude,
                    customerAddress: AuthSession.useCurrentLocation
                        ? null
                        : AuthSession.address,
                    storeAddress: _storeAddressByName[
                        product.storeName.trim().toLowerCase()],
                    onBuyNow: () async {
                      if (product.units.length > 1) {
                        await showVariantSelectionSheet(context, product);
                        return;
                      }

                      final defaultUnit =
                          product.units.isNotEmpty ? product.units.first : null;
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
                          content: Text(
                            context.tr(
                                vi: 'Đã thêm vào giỏ hàng',
                                en: 'Added to cart'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
