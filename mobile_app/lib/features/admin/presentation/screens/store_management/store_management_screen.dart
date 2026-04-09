import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/store_management/store_detail_screen.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/store_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';

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
  Map<String, double> _storeRevenueMap = {};
  bool _isLoadingRevenue = false;

  @override
  void initState() {
    super.initState();
    _loadStoreRevenue();
  }

  Future<void> _loadStoreRevenue() async {
    setState(() => _isLoadingRevenue = true);
    try {
      final orders = await _orderService.getAllOrdersAdmin();
      final Map<String, double> revenueMap = {};
      for (var o in orders) {
        final status = (o.status ?? '').toUpperCase();
        if (status != 'CANCELLED') {
           final sId = (o.storeId ?? o.storeName ?? 'Khác').toString();
           revenueMap[sId] = (revenueMap[sId] ?? 0) + (o.totalAmount ?? 0).toDouble();
        }
      }
      if (!mounted) return;
      setState(() {
        _storeRevenueMap = revenueMap;
        _isLoadingRevenue = false;
      });
    } catch (e) {
      debugPrint('Error loading store revenue: $e');
      if (!mounted) return;
      setState(() => _isLoadingRevenue = false);
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản lý Cửa hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: _exportStores,
            tooltip: 'Xuất Excel',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc địa chỉ...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStoreDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add_business, color: Colors.white),
      ),
      body: _buildStoreList(),
    );
  }

  Widget _buildStoreList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _storeRepository.getStores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
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
              // Assuming 'isOpen' or 'status' field indicates if approval is needed
              final bool isPending = store['isOpen'] == 'pending' || store['status'] == 'PENDING';
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.store, color: Colors.indigo, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store['storeName'] ?? 'Cửa hàng ẩn', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Chủ CH: ${store['ownerName'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(store['isOpen']),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                   const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                   const SizedBox(width: 4),
                   Expanded(child: Text(store['address'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng doanh thu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(_currencyFormat.format(revenue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                  ),
                  if (isPending) _buildActionButtons(store['id']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic isOpen) {
    final bool active = isOpen == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? 'Mở cửa' : 'Đóng cửa', style: TextStyle(color: active ? Colors.green[700] : Colors.red[700], fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButtons(dynamic storeId) {
    return Row(
      children: [
        IconButton(
          onPressed: () async {
            await _storeRepository.rejectStore(storeId);
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
        ),
        IconButton(
          onPressed: () async {
            await _storeRepository.approveStore(storeId);
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
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
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Không tìm thấy cửa hàng', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}
