import 'package:flutter/material.dart';

import '../../../../core/cart/cart_session.dart';
import '../../../../core/format/formatters.dart';
import '../../../../features/customer/home/data/product_model.dart';
import 'product_detail_screen.dart';

const Color _primaryBlue = Color(0xFF2F80ED);
const Color _softBg = Color(0xFFF6F8FB);

class ProductSearchScreen extends StatelessWidget {
  const ProductSearchScreen({
    super.key,
    required this.query,
    required this.products,
  });

  final String query;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final keyword = query.trim();
    final lower = keyword.toLowerCase();
    final results = keyword.isEmpty
        ? <ProductModel>[]
        : products
            .where((p) => p.name.toLowerCase().contains(lower))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(keyword.isEmpty ? 'Tìm kiếm' : keyword),
      ),
      body: Container(
        color: _softBg,
        child: results.isEmpty
            ? Center(
                child: Text(
                  keyword.isEmpty
                      ? 'Nhập từ khóa để tìm sản phẩm'
                      : 'Không tìm thấy sản phẩm phù hợp',
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final product = results[index];
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
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: product.imageUrl.isEmpty
                                  ? Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    )
                                  : (product.imageUrl.startsWith('assets/'))
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
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image),
                                            );
                                          },
                                        ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _primaryBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        formatVnd(product.displayPrice),
                                        style: const TextStyle(
                                          color: _primaryBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        CartSession.addProduct(product);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            behavior:
                                                SnackBarBehavior.floating,
                                            content: Text(
                                                'Đã thêm vào giỏ hàng'),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryBlue,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.add_shopping_cart,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
