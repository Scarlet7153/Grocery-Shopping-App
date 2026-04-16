import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../features/customer/home/data/product_model.dart';
import '../services/customer_delivery_estimate_service.dart';
import '../utils/customer_l10n.dart';
import 'customer_product_image.dart';

class CustomerProductListCard extends StatelessWidget {
  const CustomerProductListCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onBuyNow,
    this.customerAddress,
    this.customerLatitude,
    this.customerLongitude,
    this.storeAddress,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onBuyNow;
  final String? customerAddress;
  final double? customerLatitude;
  final double? customerLongitude;
  final String? storeAddress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      product.storeName.isEmpty
                          ? context.tr(
                              vi: 'Cửa hàng đang cập nhật',
                              en: 'Store updating',
                            )
                          : product.storeName,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if ((customerAddress ?? '').trim().isNotEmpty &&
                    (storeAddress ?? '').trim().isNotEmpty ||
                (customerLatitude != null &&
                    customerLongitude != null &&
                    (storeAddress ?? '').trim().isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: _DeliveryInfoLine(
                  customerAddress: customerAddress,
                  customerLatitude: customerLatitude,
                  customerLongitude: customerLongitude,
                  storeAddress: storeAddress!,
                ),
              ),
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerProductImage(
                    imageUrl: product.imageUrl,
                    width: 96,
                    height: 96,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (product.categoryName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              product.categoryName,
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                formatVnd(product.displayPrice),
                                style: TextStyle(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  height: 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: onBuyNow,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7A1A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.tr(vi: 'Mua ngay', en: 'Buy now'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
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
          ],
        ),
      ),
    );
  }
}

class _DeliveryInfoLine extends StatelessWidget {
  const _DeliveryInfoLine({
    this.customerAddress,
    this.customerLatitude,
    this.customerLongitude,
    required this.storeAddress,
  });

  final String? customerAddress;
  final double? customerLatitude;
  final double? customerLongitude;
  final String storeAddress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<CustomerDeliveryEstimate?>(
      future: (customerLatitude != null && customerLongitude != null)
          ? CustomerDeliveryEstimateService.instance.estimateByCurrentLocation(
              customerLatitude: customerLatitude!,
              customerLongitude: customerLongitude!,
              storeAddress: storeAddress,
            )
          : CustomerDeliveryEstimateService.instance.estimateByAddress(
              customerAddress: (customerAddress ?? '').trim(),
              storeAddress: storeAddress,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr(
                  vi: 'Đang tính quãng đường...',
                  en: 'Calculating distance...',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }

        final estimate = snapshot.data;
        if (estimate == null) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              estimate.distanceLabel,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.schedule_outlined,
                size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              estimate.durationLabel,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
