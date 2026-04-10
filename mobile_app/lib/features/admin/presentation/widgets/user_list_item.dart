import 'package:flutter/material.dart';
import '../../../auth/models/user_model.dart';
import 'package:intl/intl.dart';

class UserListItem extends StatelessWidget {
  final UserModel user;
  final Function(UserStatus) onStatusChanged;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.user,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = user.status == UserStatus.active;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                  child: Text(
                    user.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phoneNumber,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (user.storeName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.store, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.storeName!,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Hoạt động' : 'Đã khóa',
                    style: TextStyle(
                      color: isActive ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tham gia: ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Show confirmation bottom sheet or dialog
                    _showStatusToggleDialog(context);
                  },
                  icon: Icon(
                    isActive ? Icons.lock : Icons.lock_open,
                    size: 18,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                  label: Text(
                    isActive ? 'Khóa tài khoản' : 'Mở khóa',
                    style: TextStyle(
                      color: isActive ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return Colors.green;
      case UserRole.store:
        return Colors.blue;
      case UserRole.shipper:
        return Colors.orange;
      case UserRole.admin:
        return Colors.purple;
    }
  }

  void _showStatusToggleDialog(BuildContext context) {
    final bool willBlock = user.status == UserStatus.active;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(willBlock ? 'Xác nhận khóa' : 'Biết nhận mở khóa'),
        content: Text(
          willBlock 
            ? 'Bạn có chắc chắn muốn khóa tài khoản của ${user.fullName}? Người dùng này sẽ không thể đăng nhập vào hệ thống.'
            : 'Bạn có chắc chắn muốn mở khóa cho tài khoản ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStatusChanged(willBlock ? UserStatus.inactive : UserStatus.active);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willBlock ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(willBlock ? 'Khóa' : 'Mở'),
          ),
        ],
      ),
    );
  }
}
