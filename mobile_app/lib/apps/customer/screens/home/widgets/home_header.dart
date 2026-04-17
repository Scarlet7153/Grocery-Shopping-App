import 'package:flutter/material.dart';

import '../../../utils/customer_l10n.dart';
import 'package:grocery_shopping_app/features/notification/presentation/widgets/notification_icon_button.dart';

class CustomerHomeHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String name;
  final String location;
  final String? avatarUrl;
  final bool isUsingCurrentLocation;
  final VoidCallback? onUseCurrentLocationTap;
  final VoidCallback? onTap;

  const CustomerHomeHeader({
    super.key,
    required this.name,
    required this.location,
    this.avatarUrl,
    this.isUsingCurrentLocation = true,
    this.onUseCurrentLocationTap,
    this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: scheme.primaryContainer,
            foregroundImage: hasAvatar ? NetworkImage(avatarUrl!.trim()) : null,
            child: Icon(Icons.person, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr(vi: 'Xin chào', en: 'Hello')}, $name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 20),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isUsingCurrentLocation &&
                        onUseCurrentLocationTap != null)
                      GestureDetector(
                        onTap: onUseCurrentLocationTap,
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            context.tr(
                              vi: 'Dùng vị trí hiện tại',
                              en: 'Use current location',
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
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
      actions: const [
        NotificationIconButton(),
        SizedBox(width: 4),
      ],
    );
  }
}
