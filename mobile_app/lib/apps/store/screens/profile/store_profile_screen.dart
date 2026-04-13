import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/ui/ui_constants.dart';

import '../../block/store_dashboard_bloc.dart';
import '../../repository/store_repository.dart';

/// Design system — Grab Merchant (#00B14F)
const Color _kPrimary = Color(0xFF00B14F);
const Color _kSurface = Color(0xFFF5F6FA);
const Color _kCardShadow = Color(0x0A000000);

String _storeStatusLabelVi(Map<String, dynamic>? m) {
  if (m == null) return '—';
  final v = m['isOpen'];
  if (v == true) return 'Đang mở';
  if (v == false) return 'Đang đóng';
  return '—';
}

class StoreProfileScreen extends StatefulWidget {
  final String token;

  const StoreProfileScreen({super.key, required this.token});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  bool _toggleBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<StoreDashboardBloc>().state;
      if (s is! StoreDashboardLoaded) {
        context.read<StoreDashboardBloc>().add(
              LoadStoreDashboard(widget.token),
            );
      }
    });
  }

  Future<void> _onToggleStoreOpen(bool currentlyOpen) async {
    if (_toggleBusy) return;
    if (currentlyOpen) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Đóng cửa hàng?'),
          content: const Text(
            'Khách sẽ thấy cửa hàng đang đóng. Bạn có chắc muốn đóng cửa?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đóng cửa'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final bloc = context.read<StoreDashboardBloc>();
    final state = bloc.state;
    if (state is! StoreDashboardLoaded) return;

    final repo = StoreRepository();
    final storeId = repo.parseStoreId(state.store);
    if (storeId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được cửa hàng.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _toggleBusy = true);
    try {
      final patch = await repo.toggleStoreStatus(widget.token, storeId);
      if (!mounted) return;
      bloc.add(MergeStoreDashboardState(patch));
      bloc.add(LoadStoreDashboard(widget.token, showLoading: false));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyOpen ? 'Đã đóng cửa hàng.' : 'Đã mở cửa hàng.',
          ),
          backgroundColor: _kPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      if (mounted) setState(() => _toggleBusy = false);
    }
  }

  Future<void> _showEditStoreSheet({
    required String token,
    required int storeId,
    required String initialName,
    required String initialAddress,
  }) async {
    final nameC = TextEditingController(
      text: initialName == '—' ? '' : initialName,
    );
    final addrC = TextEditingController(
      text: initialAddress == '—' ? '' : initialAddress,
    );
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          var saving = false;
          return StatefulBuilder(
            builder: (dialogContext, setDlg) {
              return AlertDialog(
              title: const Text('Cập nhật thông tin cửa hàng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: 'Tên cửa hàng',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addrC,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final n = nameC.text.trim();
                          final a = addrC.text.trim();
                          if (n.isEmpty || a.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập đủ tên cửa hàng và địa chỉ.',
                                ),
                                backgroundColor: Color(0xFFD32F2F),
                              ),
                            );
                            return;
                          }
                          saving = true;
                          setDlg(() {});
                          try {
                            final repo = StoreRepository();
                            final patch = await repo.updateStore(
                              token: token,
                              storeId: storeId,
                              storeName: n,
                              address: a,
                            );
                            if (!context.mounted) return;
                            final bloc = context.read<StoreDashboardBloc>();
                            bloc.add(MergeStoreDashboardState(patch));
                            bloc.add(
                              LoadStoreDashboard(
                                token,
                                showLoading: false,
                              ),
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã cập nhật thông tin cửa hàng.',
                                ),
                                backgroundColor: _kPrimary,
                              ),
                            );
                          } catch (e) {
                            saving = false;
                            if (dialogContext.mounted) {
                              setDlg(() {});
                            }
                            if (!context.mounted) return;
                            final msg = e
                                .toString()
                                .replaceFirst(RegExp(r'^Exception: '), '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: const Color(0xFFD32F2F),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu'),
                ),
              ],
            );
            },
          );
        },
      );
    } finally {
      nameC.dispose();
      addrC.dispose();
    }
  }

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
      body: BlocBuilder<StoreDashboardBloc, StoreDashboardState>(
        builder: (context, state) {
          if (state is StoreDashboardError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(kPaddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message.isNotEmpty
                          ? state.message
                          : 'Không tải được thông tin cửa hàng.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.read<StoreDashboardBloc>().add(
                            LoadStoreDashboard(widget.token),
                          ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is! StoreDashboardLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }

          final store = state.store;
          final storeName = store['storeName']?.toString() ?? '—';
          final address = store['address']?.toString() ?? '—';
          final status = _storeStatusLabelVi(store);
          final isOpen = store['isOpen'] == true;
          final storeId = StoreRepository().parseStoreId(store);
          final phone = store['ownerPhone']?.toString() ?? '—';

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              kPaddingLarge,
              kPaddingMedium,
              kPaddingLarge,
              isWide ? 40 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 520 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'Thông tin cửa hàng'),
                    const SizedBox(height: 12),
                    _StoreHeaderCard(
                      storeName: storeName,
                      address: address,
                      status: status,
                      isOpen: isOpen,
                      showToggle: storeId != null,
                      toggleBusy: _toggleBusy,
                      onToggle: storeId != null
                          ? () => _onToggleStoreOpen(isOpen)
                          : null,
                    ),
                    const SizedBox(height: kSectionSpacing),
                    const _SectionTitle(title: 'Thông tin liên hệ'),
                    const SizedBox(height: 12),
                    _InfoCard(
                      items: [
                        _InfoRow(
                          icon: Icons.phone_rounded,
                          label: 'Số điện thoại',
                          value: phone,
                        ),
                        const _InfoRow(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: kSectionSpacing),
                    const _SectionTitle(title: 'Giờ hoạt động'),
                    const SizedBox(height: 12),
                    const _InfoCard(
                      items: [
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Mở cửa',
                          value: '07:00 - 22:00',
                        ),
                      ],
                    ),
                    const SizedBox(height: kSectionSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: storeId == null
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Không xác định được cửa hàng.',
                                    ),
                                    backgroundColor: Color(0xFFD32F2F),
                                  ),
                                );
                              }
                            : () => _showEditStoreSheet(
                                  token: widget.token,
                                  storeId: storeId,
                                  initialName: storeName,
                                  initialAddress: address,
                                ),
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: kIconSizeSmall,
                        ),
                        label: const Text('Cập nhật thông tin cửa hàng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoreHeaderCard extends StatelessWidget {
  final String storeName;
  final String address;
  final String status;
  final bool isOpen;
  final bool showToggle;
  final bool toggleBusy;
  final VoidCallback? onToggle;

  const _StoreHeaderCard({
    required this.storeName,
    required this.address,
    required this.status,
    required this.isOpen,
    required this.showToggle,
    required this.toggleBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
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
                child: const Icon(
                  Icons.store_rounded,
                  color: _kPrimary,
                  size: 44,
                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _kPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
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
              Icon(
                Icons.location_on_rounded,
                size: 22,
                color: Colors.grey.shade600,
              ),
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
          if (showToggle && onToggle != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: toggleBusy ? null : onToggle,
                icon: Icon(
                  isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                  size: 20,
                ),
                label: Text(isOpen ? 'Đóng cửa hàng' : 'Mở cửa hàng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isOpen
                      ? const Color(0xFFD32F2F)
                      : _kPrimary,
                  side: BorderSide(
                    color: isOpen
                        ? const Color(0xFFD32F2F)
                        : _kPrimary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                  ),
                ),
              ),
            ),
          ],
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
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(children: items),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
