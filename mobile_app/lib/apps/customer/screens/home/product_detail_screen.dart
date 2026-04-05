import 'package:flutter/material.dart';

import '../../../../features/customer/home/data/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 48),
                      )
                    : (product.imageUrl.startsWith('assets/'))
                        ? Image.asset(
                            product.imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 48),
                              );
                            },
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${product.displayPrice.toStringAsFixed(0)}\u0111',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (product.storeName.isNotEmpty)
              Text(
                'C\u1eeda h\u00e0ng: ${product.storeName}',
                style: const TextStyle(fontSize: 14),
              ),
            if (product.categoryName.isNotEmpty)
              Text(
                'Danh m\u1ee5c: ${product.categoryName}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 12),
            Text(
              product.description.isEmpty
                  ? 'Ch\u01b0a c\u00f3 m\u00f4 t\u1ea3 s\u1ea3n ph\u1ea9m.'
                  : product.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'C\u00e1c \u0111\u01a1n v\u1ecb b\u00e1n',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (product.units.isEmpty)
              const Text('Ch\u01b0a c\u00f3 \u0111\u01a1n v\u1ecb b\u00e1n.')
            else
              Column(
                children: product.units.map((unit) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(unit.unitName),
                    subtitle: Text('T\u1ed3n: ${unit.stockQuantity}'),
                    trailing: Text(
                      '${unit.price.toStringAsFixed(0)}\u0111',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
