import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/enums/app_type.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/user_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_user_repository_impl.dart';
import 'package:grocery_shopping_app/features/admin/presentation/widgets/user_list_item.dart';
import 'package:grocery_shopping_app/features/admin/presentation/widgets/user_list_item.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/user_management/user_detail_screen.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  final UserRole? initialRole;
  const UserManagementScreen({super.key, this.initialRole});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  String _searchQuery = '';
  UserStatus? _statusFilter;

  final List<UserRole> _roles = [
    UserRole.customer,
    UserRole.store,
    UserRole.shipper,
    UserRole.admin,
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = widget.initialRole != null ? _roles.indexOf(widget.initialRole!) : 0;
    if (initialIndex == -1) initialIndex = 0;
    _tabController = TabController(length: _roles.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    String fullName = '';
    String phoneNumber = '';
    String password = '';
    UserRole selectedRole = _roles[_tabController.index];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Thêm người dùng mới', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: _inputDecoration('Họ và tên', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                        onSaved: (v) => fullName = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _inputDecoration('Số điện thoại', Icons.phone_android_outlined),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập SĐT';
                          if (!RegExp(r'^0\d{9}$').hasMatch(v)) return 'SĐT không hợp lệ';
                          return null;
                        },
                        onSaved: (v) => phoneNumber = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _inputDecoration('Mật khẩu', Icons.lock_outline),
                        obscureText: true,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                        onSaved: (v) => password = v!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: _inputDecoration('Vai trò', Icons.shield_outlined),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedRole = val!),
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
                      final newUser = UserModel(
                        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                        fullName: fullName,
                        phoneNumber: phoneNumber,
                        role: selectedRole,
                        status: UserStatus.active,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      await _userRepository.createUser(newUser, password: password);
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {});
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
        title: const Text('Quản lý Người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_statusFilter == null ? Icons.filter_list : Icons.filter_list_off, color: Colors.indigo),
            onPressed: () {
              setState(() {
                if (_statusFilter == null) {
                  _statusFilter = UserStatus.active;
                } else if (_statusFilter == UserStatus.active) {
                  _statusFilter = UserStatus.inactive;
                } else {
                  _statusFilter = null;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_statusFilter == null ? 'Hiển thị tất cả' : 'Lọc: ${_statusFilter == UserStatus.active ? 'Hoạt động' : 'Đã khóa'}'),
                duration: const Duration(seconds: 1),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: _exportUsers,
            tooltip: 'Xuất Excel',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc SĐT...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.indigo,
                indicatorWeight: 3,
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: _roles.map((role) => Tab(text: _getRoleDisplayName(role))).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _roles.map((role) => _buildUserList(role)).toList(),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.customer: return 'Khách hàng';
      case UserRole.store: return 'Cửa hàng';
      case UserRole.shipper: return 'Shipper';
      case UserRole.admin: return 'Admin';
    }
  }

  Widget _buildUserList(UserRole role) {
    return FutureBuilder<List<UserModel>>(
      future: _userRepository.getUsers(role: role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }
        
        final List<UserModel> allUsers = snapshot.data ?? [];
        final List<UserModel> filteredUsers = allUsers.where((u) {
          final matchesSearch = u.fullName.toLowerCase().contains(_searchQuery) || u.phoneNumber.contains(_searchQuery);
          final matchesStatus = _statusFilter == null || u.status == _statusFilter;
          return matchesSearch && matchesStatus;
        }).toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              return UserListItem(
                user: filteredUsers[index],
                onStatusChanged: (newStatus) async {
                  await _userRepository.updateUserStatus(filteredUsers[index].id, newStatus);
                  setState(() {});
                },
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(user: filteredUsers[index])));
                  setState(() {});
                },
              );
            },
          ),
        );
      },
    );
  }

  void _exportUsers() async {
    try {
      // Fetch all users across all roles to export
      final List<UserModel> allUsers = [];
      await Future.wait(_roles.map((role) async {
        final users = await _userRepository.getUsers(role: role);
        allUsers.addAll(users);
      }));

      final exportData = allUsers.map((u) => {
        'ID': u.id,
        'Họ tên': u.fullName,
        'SĐT': u.phoneNumber,
        'Vai trò': _getRoleDisplayName(u.role),
        'Trạng thái': u.status == UserStatus.active ? 'Hoạt động' : 'Đã khóa',
        'Ngày tạo': DateFormat('dd/MM/yyyy').format(u.createdAt),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_nguoidung_${DateFormat('yyyyMMdd').format(DateTime.now())}',
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
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Không tìm thấy người dùng phù hợp', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}
