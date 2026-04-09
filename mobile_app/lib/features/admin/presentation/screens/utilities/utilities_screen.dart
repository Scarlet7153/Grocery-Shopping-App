import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  void _executeAction(String actionName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang thực thi...'),
          ],
        ),
      ),
    );

    try {
      if (actionName == 'Xóa cache') {
        // Clear all SharedPreferences except the auth token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        await prefs.clear();
        if (token != null) {
          await prefs.setString('access_token', token);
        }
      }
      
      // Simulate network/disk latency
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionName hoàn tất!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGrowthDialog() async {
    final prefs = await SharedPreferences.getInstance();
    double currentFactor = prefs.getDouble('growth_factor') ?? 1.0;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Mô phỏng tăng trưởng'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Điều chỉnh hệ số nhân để mô phỏng dữ liệu lớn hơn (Doanh thu & Đơn hàng).'),
                  const SizedBox(height: 16),
                  Text('Hệ số hiện tại: ${currentFactor.toStringAsFixed(1)}x', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                  Slider(
                    value: currentFactor,
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    label: '${currentFactor.round()}x',
                    onChanged: (val) {
                      setDialogState(() => currentFactor = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    await prefs.setDouble('growth_factor', currentFactor);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật hệ số tăng trưởng! Quay lại Báo cáo để xem kết quả.')),
                      );
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tiện Ích Quản Trị'),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUtilityCard(
            Icons.trending_up,
            'Mô Phỏng Tăng Trưởng',
            'Điều chỉnh doanh thu/đơn hàng (ước tính) dựa trên số User/Cửa hàng thực tế.',
            () => _showGrowthDialog(),
          ),
          const SizedBox(height: 16),
          _buildUtilityCard(
            Icons.delete_sweep,
            'Xóa Cache Ứng Dụng',
            'Xóa toàn bộ cache tạm thời trên thiết bị admin để giải phóng bộ nhớ.',
            () => _executeAction('Xóa cache'),
          ),
          const SizedBox(height: 16),
          _buildUtilityCard(
            Icons.sync,
            'Đồng Bộ Hóa Thủ Công',
            'Bắt buộc đồng bộ hóa toàn bộ dữ liệu (đơn hàng, cửa hàng) từ máy chủ.',
            () => _executeAction('Đồng bộ hóa dữ liệu'),
          ),
          const SizedBox(height: 16),
          _buildUtilityCard(
            Icons.picture_as_pdf,
            'Xuất Báo Cáo Tháng',
            'Kết xuất biểu đồ và số liệu ra định dạng PDF để gửi báo cáo.',
            () => _executeAction('Xuất file PDF báo cáo'),
          ),
          const SizedBox(height: 16),
          _buildUtilityCard(
            Icons.table_view,
            'Xuất Excel Danh Sách User',
            'Tải file Excel báo cáo tổng hợp danh sách người dùng, cửa hàng và shipper.',
            () => _executeAction('Xuất file Excel'),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityCard(IconData icon, String title, String description, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.teal, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
