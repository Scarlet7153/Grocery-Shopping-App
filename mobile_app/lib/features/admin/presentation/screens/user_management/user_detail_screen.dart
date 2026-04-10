import 'package:flutter/material.dart';
import '../../../../auth/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/repositories/api_user_repository_impl.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late UserModel _user;
  bool _isLoading = false;
  List<OrderModel> _userOrders = [];

  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUserOrders();
  }

  Future<void> _loadUserOrders() async {
    setState(() => _isLoading = true);
    try {
      final allOrders = await _orderService.getAllOrdersAdmin();
      final userIdStr = _user.id.toString();
      
      setState(() {
        _userOrders = allOrders.where((o) => 
          o.customerId?.toString() == userIdStr || o.shipperId?.toString() == userIdStr
        ).toList();
      });
    } catch (e) {
      debugPrint('Error loading user orders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa ${_user.fullName}? Mọi dữ liệu liên quan sẽ bị mất.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _userRepository.deleteUser(_user.id);
      if (mounted) {
        Navigator.pop(context); // Go back to list
      }
    }
  }

  void _editUser() {
    final formKey = GlobalKey<FormState>();
    String newName = _user.fullName;
    String newPhone = _user.phoneNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: newName,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                onSaved: (val) => newName = val!,
              ),
              TextFormField(
                initialValue: newPhone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                onSaved: (val) => newPhone = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              formKey.currentState!.save();
              setState(() => _isLoading = true);
              Navigator.pop(context);
              final updated = _user.copyWith(fullName: newName, phoneNumber: newPhone);
              await _userRepository.updateUser(updated);
              setState(() {
                _user = updated;
                _isLoading = false;
              });
            },
            child: const Text('Lưu'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustomer = _user.role == UserRole.customer;
    final bool isShipper = _user.role == UserRole.shipper;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editUser,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteUser,
          ),
        ],
      ),
      body: _isLoading && _userOrders.isEmpty
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadUserOrders,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  
                  if (isCustomer) ...[
                    const Text('Giỏ hàng chi tiết (Demo)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._cartItems.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_cart, color: Colors.orange),
                        title: Text(item['name']),
                        subtitle: Text('Cửa hàng: ${item['store']}'),
                        trailing: Text('x${item['qty']}'),
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],

                  if (isShipper) ...[
                    const Text('Đơn hàng được giao (Thực tế)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_userOrders.isEmpty)
                      _buildEmptySection('Chưa có lịch sử giao hàng thực tế')
                    else
                      ..._userOrders.map((o) => _buildOrderTile(o)),
                    const SizedBox(height: 24),
                  ],

                  if (!isShipper) ...[
                    const Text('Lịch sử đơn hàng (Thực tế)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_userOrders.isEmpty)
                      _buildEmptySection('Chưa có đơn hàng nào thực tế trong DB')
                    else
                      ..._userOrders.map((o) => _buildOrderTile(o)),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOrderTile(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Đơn hàng #${order.id}'),
        subtitle: Text('Tổng: ${_currencyFormat.format(order.totalAmount)}'),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
          child: Text(order.status ?? 'N/A', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                // Mock avatar change
                final updated = _user.copyWith(avatarUrl: 'mock_avatar_url');
                setState(() => _isLoading = true);
                await _userRepository.updateUser(updated);
                setState(() {
                  _user = updated;
                  _isLoading = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật avatar thành công!')));
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    backgroundImage: _user.avatarUrl != null 
                        ? const NetworkImage('https://i.pravatar.cc/150') // Fake UI image
                        : null,
                    child: _user.avatarUrl == null
                        ? Text(
                            _user.fullName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_user.roleDisplayName, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const Divider(height: 32),
            _buildInfoRow(Icons.phone, 'Số điện thoại', _user.phoneNumber),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Ngày tham gia', _user.createdAt.toString().split(' ')[0]),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.local_activity, 'Trạng thái', _user.isActive ? 'Đang hoạt động' : 'Bị khóa', color: _user.isActive ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color ?? Colors.black87),
        ),
      ],
    );
  }
}
