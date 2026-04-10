import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/shipper_dashboard_bloc.dart';
import '../../models/shipper_order.dart';
import '../../repository/shipper_repository.dart';
import '../../services/shipper_realtime_stomp_service.dart';
import '../../../../core/theme/shipper_theme.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final ShipperOrder order;
  final VoidCallback? onConfirm;

  const DeliveryConfirmationScreen({
    super.key,
    required this.order,
    this.onConfirm,
  });

  @override
  State<DeliveryConfirmationScreen> createState() =>
      _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState
    extends State<DeliveryConfirmationScreen> {
  XFile? _proofImage;
  Uint8List? _proofImageBytes;
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRealtimeSyncing = false;
  StreamSubscription<ShipperRealtimeEvent>? _realtimeSubscription;
  final ShipperRealtimeStompService _realtimeService =
      ShipperRealtimeStompService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealtimeStreaming();
      }
    });
  }

  Future<void> _initRealtimeStreaming() async {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      if (!_isEventForCurrentOrder(event)) return;

      switch (event.type) {
        case ShipperRealtimeEventType.orderStatusChanged:
          _handleRealtimeStatusChanged(event);
          break;
        case ShipperRealtimeEventType.error:
          debugPrint('DeliveryConfirmation STOMP error: ${event.message}');
          break;
        case ShipperRealtimeEventType.connected:
        case ShipperRealtimeEventType.disconnected:
        case ShipperRealtimeEventType.orderCreated:
        case ShipperRealtimeEventType.orderAccepted:
        case ShipperRealtimeEventType.profileUpdated:
          break;
      }
    });

    await _realtimeService.connect();
  }

  bool _isEventForCurrentOrder(ShipperRealtimeEvent event) {
    final payload = event.payload;
    if (payload == null) return false;

    final rawOrderId = payload['orderId'] ?? payload['id'];
    final eventOrderId = rawOrderId is int
        ? rawOrderId
        : int.tryParse(rawOrderId?.toString() ?? '');

    return eventOrderId == widget.order.id;
  }

  Future<void> _handleRealtimeStatusChanged(ShipperRealtimeEvent event) async {
    if (!mounted || _isRealtimeSyncing) return;

    final newStatus = event.payload?['newStatus']?.toString();
    if (newStatus != 'DELIVERED') return;

    _isRealtimeSyncing = true;
    try {
      final repository = context.read<ShipperRepository>();
      final refreshed = await repository.getOrderById(widget.order.id);
      if (!mounted) return;

      Navigator.of(context).pop(refreshed ?? widget.order);
    } catch (e) {
      debugPrint('Realtime refresh failed in DeliveryConfirmation: $e');
    } finally {
      _isRealtimeSyncing = false;
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _proofImage = pickedFile;
          _proofImageBytes = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
      }
    }
  }

  Future<void> _confirmDelivery() async {
    if (_proofImage == null || _proofImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp ảnh chứng minh giao hàng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final repository = context.read<ShipperRepository>();

      final podImageUrl = await repository.uploadPOD(_proofImage!, widget.order.id);
      if (podImageUrl == null || podImageUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload ảnh chứng minh giao hàng thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final updatedOrder = await repository.updateOrderStatus(
        widget.order.id,
        'DELIVERED',
        podImageUrl: podImageUrl,
      );

      if (updatedOrder == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể cập nhật trạng thái đơn hàng'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        context.read<ShipperDashboardBloc>().add(RefreshDashboardData());
        widget.onConfirm?.call();
        Navigator.of(context).pop(updatedOrder);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xác nhận: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Xác nhận giao hàng'),
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== ORDER SUMMARY (16px+) =====
            _buildOrderSummary(),
            const SizedBox(height: 20),

            // ===== DELIVERY DETAILS (16px+) =====
            _buildDeliveryDetails(),
            const SizedBox(height: 20),

            // ===== PROOF OF DELIVERY =====
            _buildProofSection(),
            const SizedBox(height: 28),

            // ===== CONFIRM BUTTON (56px - THUMB ZONE) =====
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _confirmDelivery,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 22),
                label: Text(
                  _isUploading ? 'Đang xác nhận...' : 'Xác nhận giao hàng',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShipperTheme.successColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final itemCount = widget.order.items.length;
    final totalPrice = (widget.order.grandTotal as num?) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShipperTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (18px)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thông tin đơn hàng',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Order details (16px body text)
          _buildDetailRow('Mã đơn', '#${widget.order.id}'),
          const SizedBox(height: 12),
          _buildDetailRow('Cửa hàng', widget.order.storeName),
          const SizedBox(height: 12),
          _buildDetailRow('Số lượng', '$itemCount sản phẩm'),
          const SizedBox(height: 14),

          // Total price (green, 16px)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng tiền',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ShipperTheme.textGreyColor,
                ),
              ),
              Text(
                '${totalPrice.toStringAsFixed(0)} ₫',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ShipperTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDeliveryDetails() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShipperTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (18px)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thông tin giao nhận',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer name (16px body)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person,
                color: ShipperTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khách hàng',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.order.customerName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Phone (16px body, clickable)
          InkWell(
            onTap: () async {
              try {
                await launchUrl(
                  Uri(scheme: 'tel', path: widget.order.customerPhone),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể gọi')),
                  );
                }
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.phone,
                  color: ShipperTheme.secondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số điện thoại',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.order.customerPhone,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ShipperTheme.secondaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Address (16px body)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.home,
                color: ShipperTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Địa chỉ giao',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.order.deliveryAddress,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (18px)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Chứng minh giao hàng',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_proofImage != null)
          Column(
            children: [
              // Image preview (280px)
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ShipperTheme.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_proofImageBytes!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),

              // Retake button (48px secondary)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text(
                    'Chụp ảnh khác',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              // Empty state
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ShipperTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 56,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có ảnh chứng minh',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ShipperTheme.textLightGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action buttons (48px each)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text(
                        'Chụp ảnh',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShipperTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.image, size: 20),
                      label: const Text(
                        'Chọn từ thư viện',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
