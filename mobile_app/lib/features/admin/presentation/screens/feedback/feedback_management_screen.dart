import 'package:flutter/material.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final List<Map<String, dynamic>> _feedbacks = [
    {
      'id': 'fb1',
      'user': 'Trần Vân Tùng',
      'type': 'Lỗi ứng dụng',
      'content': 'Tôi không thể thanh toán bằng thẻ tín dụng lúc 2h chiều nay.',
      'status': 'Chưa xử lý',
      'date': 'Hôm nay, 14:30',
    },
    {
      'id': 'fb2',
      'user': 'Nguyễn Thị Hoa',
      'type': 'Khiếu nại Shipper',
      'content': 'Shipper giao hàng trễ 30 phút so với dự kiến.',
      'status': 'Đã xử lý',
      'date': 'Hôm qua, 09:15',
    },
    {
      'id': 'fb3',
      'user': 'Lê Minh',
      'type': 'Góp ý hệ thống',
      'content': 'App nên bổ sung tính năng lưu danh sách chợ yêu thích.',
      'status': 'Chưa xử lý',
      'date': '01/10/2023',
    },
  ];

  void _toggleStatus(int index) {
    setState(() {
      _feedbacks[index]['status'] = _feedbacks[index]['status'] == 'Đã xử lý' ? 'Chưa xử lý' : 'Đã xử lý';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật trạng thái phản hồi')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản Lý Phản Hồi'),
        backgroundColor: Colors.pink[600],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final fb = _feedbacks[index];
          final bool isResolved = fb['status'] == 'Đã xử lý';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(fb['type'], style: TextStyle(color: Colors.pink[700], fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Text(fb['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Từ: ${fb['user']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(fb['content'], style: const TextStyle(fontSize: 15)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isResolved ? Icons.check_circle : Icons.pending,
                            color: isResolved ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fb['status'],
                            style: TextStyle(
                              color: isResolved ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _toggleStatus(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isResolved ? Colors.grey[200] : Colors.green[50],
                          foregroundColor: isResolved ? Colors.black : Colors.green[800],
                        ),
                        child: Text(isResolved ? 'Đánh dấu Chưa xử lý' : 'Đánh dấu Đã xử lý'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
