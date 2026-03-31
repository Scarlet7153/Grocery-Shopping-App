import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/ui/ui_constants.dart';
import '../../widgets/scale_on_tap.dart';

/// Design system — Grab Merchant (#00B14F)
const Color _kPrimary = Color(0xFF00B14F);
const Color _kSurface = Color(0xFFF5F6FA);
const Color _kCardShadow = Color(0x0A000000);
const Color _kPrimaryLight = Color(0xFFE8F5E9);

class StoreChatScreen extends StatelessWidget {
  const StoreChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: Text(
          'Tin nhắn',
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
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              kPaddingLarge,
              kPaddingMedium,
              kPaddingLarge,
              isWide ? 32 : 28,
            ),
            children: [
              _SectionLabel(title: 'Chat với shipper'),
              const SizedBox(height: 10),
              _ChatTile(
                name: 'Shipper A',
                lastMessage: 'Đơn hàng đã lấy chưa?',
                time: '10:30',
                type: _ChatType.shipper,
                hasUnread: true,
              ),
              const SizedBox(height: kCardPadding),
              _ChatTile(
                name: 'Shipper B',
                lastMessage: 'Đơn #1235 đang trên đường.',
                time: '09:45',
                type: _ChatType.shipper,
              ),
              const SizedBox(height: kSectionSpacing),
              _SectionLabel(title: 'Chat với khách hàng'),
              const SizedBox(height: 10),
              _ChatTile(
                name: 'Khách hàng B',
                lastMessage: 'Shop chuẩn bị đơn giúp mình nhé',
                time: '09:15',
                type: _ChatType.customer,
                hasUnread: true,
              ),
              const SizedBox(height: kCardPadding),
              _ChatTile(
                name: 'Khách hàng C',
                lastMessage: 'Còn hàng không shop?',
                time: '08:50',
                type: _ChatType.customer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChatType { shipper, customer }

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

class _ChatTile extends StatefulWidget {
  final String name;
  final String lastMessage;
  final String time;
  final _ChatType type;
  final bool hasUnread;

  const _ChatTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.type = _ChatType.customer,
    this.hasUnread = false,
  });

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: () {},
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hover ? _kPrimaryLight.withValues(alpha: 0.5) : Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: _hover ? _kPrimary.withValues(alpha: 0.2) : Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(color: _kCardShadow, blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(kRadiusLarge),
              splashColor: _kPrimary.withValues(alpha: 0.12),
              highlightColor: _kPrimary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _kCardShadow,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: _kPrimary.withValues(alpha: 0.12),
                            child: Icon(
                              widget.type == _ChatType.shipper ? Icons.local_shipping_rounded : Icons.person_rounded,
                              color: _kPrimary,
                              size: kIconSizeLarge,
                            ),
                          ),
                        ),
                        if (widget.hasUnread)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: const Color(0xFF1976D2).withValues(alpha: 0.4), blurRadius: 4)],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: widget.hasUnread ? FontWeight.w700 : FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              Text(
                                widget.time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(kRadiusMedium),
                              border: Border.all(color: _kPrimary.withValues(alpha: 0.15), width: 1),
                            ),
                            child: Text(
                              widget.lastMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: kIconSizeMedium),
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
