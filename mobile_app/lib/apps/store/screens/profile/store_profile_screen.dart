import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/ui/ui_constants.dart';

/// Design system — Grab Merchant (#00B14F)
const Color _kPrimary = Color(0xFF00B14F);
const Color _kSurface = Color(0xFFF5F6FA);
const Color _kCardShadow = Color(0x0A000000);

class StoreProfileScreen extends StatelessWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: Text(
          'Thông tin cửa hàng',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          kPaddingLarge,
          kPaddingMedium,
          kPaddingLarge,
          isWide ? 40 : 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Thông tin cửa hàng'),
                const SizedBox(height: 12),
                const _StoreHeaderCard(
                  storeName: 'Siêu Thị Mini B',
                  address: '456 Lê Lợi, Q3',
                  status: 'Đang mở',
                ),
                const SizedBox(height: kSectionSpacing),
                const _SectionTitle(title: 'Thông tin liên hệ'),
                const SizedBox(height: 12),
                const _InfoCard(
                  items: [
                    _InfoRow(icon: Icons.phone_rounded, label: 'Số điện thoại', value: '0901 234 567'),
                    _InfoRow(icon: Icons.email_rounded, label: 'Email', value: 'contact@minib.vn'),
                  ],
                ),
                const SizedBox(height: kSectionSpacing),
                const _SectionTitle(title: 'Giờ hoạt động'),
                const SizedBox(height: 12),
                const _InfoCard(
                  items: [
                    _InfoRow(icon: Icons.access_time_rounded, label: 'Mở cửa', value: '07:00 - 22:00'),
                  ],
                ),
                const SizedBox(height: kSectionSpacing),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật thông tin cửa hàng (demo) — kết nối API khi triển khai'),
                          backgroundColor: _kPrimary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: kIconSizeSmall),
                    label: const Text('Cập nhật thông tin cửa hàng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreHeaderCard extends StatelessWidget {
  final String storeName;
  final String address;
  final String status;

  const _StoreHeaderCard({
    required this.storeName,
    required this.address,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
        boxShadow: const [
          BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _kPrimary.withValues(alpha: 0.12),
                child: const Icon(Icons.store_rounded, color: _kPrimary, size: 44),
              ),
              const SizedBox(width: kPaddingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: kPaddingSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 22, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
        boxShadow: const [
          BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: _kPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
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
