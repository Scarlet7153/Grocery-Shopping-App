import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/store_management/store_detail_screen.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/store_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _searchQuery = '';
  bool _showPendingOnly = false;
  Map<String, double> _storeRevenueMap = {};

  @override
  void initState() {
    super.initState();
    _loadStoreRevenue();
  }

  Future<void> _loadStoreRevenue() async {
    if (!mounted) return;
    
    try {
      // getAllOrdersAdmin giờ đây đã an toàn (không gây 403 UI)
      final orders = await _orderService.getAllOrdersAdmin();
      
      debugPrint('📊 StoreManagement: Đã tải được ${orders.length} đơn hàng qua cơ chế khám phá.');
      
      final Map<String, double> revenueMap = {};
      for (var o in orders) {
        final status = (o.status ?? '').toUpperCase();
        // Tính doanh thu dựa trên các đơn hàng không bị hủy
        if (status != 'CANCELLED') {
           final sId = o.storeId?.toString() ?? 'unknown';
           revenueMap[sId] = (revenueMap[sId] ?? 0) + (o.totalAmount ?? 0).toDouble();
        }
      }
      
      if (!mounted) return;
      setState(() {
        _storeRevenueMap = revenueMap;
      });
    } catch (e) {
      debugPrint('⚠️ Error loading store revenue (Handled): $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showAddStoreDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String ownerName = '';
    String phone = '';
    String password = '';
    String address = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thêm cửa hàng mới', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: _inputDecoration('Tên cửa hàng', Icons.store_outlined),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => name = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration('Họ tên chủ cửa hàng', Icons.person_outline),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => ownerName = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration('Số điện thoại', Icons.phone_android_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || !RegExp(r'^0\d{9}$').hasMatch(v)) ? 'SĐT không hợp lệ' : null,
                    onSaved: (v) => phone = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration('Mật khẩu', Icons.lock_outline),
                    obscureText: true,
                    validator: (v) => v!.isEmpty || v.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                    onSaved: (v) => password = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration('Địa chỉ', Icons.location_on_outlined),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => address = v!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  try {
                    await _storeRepository.createStore({
                      'name': name,
                      'ownerName': ownerName,
                      'phone': phone,
                      'password': password,
                      'address': address,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (mounted) setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm cửa hàng thành công')));
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý Cửa hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: _exportStores,
            tooltip: 'Xuất Excel',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc địa chỉ...',
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool>(
                      isExpanded: true,
                      value: _showPendingOnly,
                      icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                      items: const [
                        DropdownMenuItem(
                          value: false,
                          child: Text('Tất cả cửa hàng'),
                        ),
                        DropdownMenuItem(
                          value: true,
                          child: Text('Chờ duyệt'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _showPendingOnly = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStoreDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add_business, color: Colors.white),
      ),
      body: _buildStoreList(),
    );
  }

  Widget _buildStoreList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _storeRepository.getStores(pendingApproval: _showPendingOnly),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }

        final allStores = snapshot.data ?? [];
        final filteredStores = allStores.where((s) {
          final name = (s['storeName'] ?? '').toString().toLowerCase();
          final owner = (s['ownerName'] ?? '').toString().toLowerCase();
          final addr = (s['address'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || owner.contains(_searchQuery) || addr.contains(_searchQuery);
        }).toList();

        if (filteredStores.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadStoreRevenue();
            if (mounted) setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredStores.length,
            itemBuilder: (context, index) {
              final store = filteredStores[index];
              final bool isPending = store['status'] == 'PENDING' || _showPendingOnly;
              return _buildStoreCard(store, isPending);
            },
          ),
        );
      },
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, bool isPending) {
    final sId = store['id']?.toString() ?? store['storeName']?.toString() ?? '';
    final double revenue = _storeRevenueMap[sId] ?? (store['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: store['imageUrl'] != null && store['imageUrl'].toString().isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(store['imageUrl'].toString()),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: store['imageUrl'] == null || store['imageUrl'].toString().isEmpty
                        ? Icon(Icons.store, color: Theme.of(context).colorScheme.primary, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store['storeName'] ?? 'Cửa hàng ẩn', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Chủ CH: ${store['ownerName'] ?? 'N/A'}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(store['isOpen'], isPending: isPending),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                   Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).disabledColor),
                   const SizedBox(width: 4),
                   Expanded(child: Text(store['address'] ?? 'N/A', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng doanh thu', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                      Text(_currencyFormat.format(revenue), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  if (isPending) _buildActionButtons(store['userId'] ?? store['id']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic isOpen, {bool isPending = false}) {
    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Chờ duyệt', style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }
    final bool active = isOpen == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? 'Mở cửa' : 'Đóng cửa', style: TextStyle(color: active ? Colors.green[700] : Colors.red[700], fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButtons(dynamic userId) {
    final id = userId?.toString() ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: id.isEmpty
              ? null
              : () async {
                  try {
                    await _storeRepository.rejectStore(id);
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã từ chối cửa hàng')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                },
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
          label: const Text('Từ chối', style: TextStyle(color: Colors.red, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: id.isEmpty
              ? null
              : () async {
                  try {
                    await _storeRepository.approveStore(id);
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã duyệt cửa hàng thành công')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Duyệt', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _exportStores() async {
    try {
      final List<Map<String, dynamic>> allStores = await _storeRepository.getStores();
      
      final exportData = allStores.map((s) => {
        'ID': s['id'],
        'Tên cửa hàng': s['storeName'],
        'Chủ cửa hàng': s['ownerName'],
        'Địa chỉ': s['address'],
        'Doanh thu': _currencyFormat.format(s['totalRevenue'] ?? 0),
        'Trạng thái': s['isOpen'] == true ? 'Mở cửa' : 'Đóng cửa',
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_cuahang_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: $e')));
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text('Không tìm thấy cửa hàng', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16)),
        ],
      ),
    );
  }
}
