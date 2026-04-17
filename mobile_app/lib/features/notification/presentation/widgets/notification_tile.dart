// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Tùy chỉnh icon dựa trên type của notification
    IconData iconData = Icons.notifications;
    Color iconColor = theme.primaryColor;
    
    if (notification.type.contains('ORDER_CREATED')) {
      iconData = Icons.shopping_bag;
      iconColor = Colors.orange;
    } else if (notification.type.contains('CONFIRMED') || notification.type.contains('ASSIGNED')) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else if (notification.type.contains('DELIVER')) {
      iconData = Icons.local_shipping;
      iconColor = Colors.blue;
    } else if (notification.type.contains('CANCEL')) {
      iconData = Icons.cancel;
      iconColor = Colors.red;
    } else if (notification.type.contains('REVIEW')) {
      iconData = Icons.star;
      iconColor = Colors.amber;
    }

    String timeText = '';
    if (notification.createdAt != null) {
      final now = DateTime.now();
      final diff = now.difference(notification.createdAt!);
      if (diff.inDays > 0) {
        timeText = DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt!);
      } else if (diff.inHours > 0) {
        timeText = '${diff.inHours} giờ trước';
      } else if (diff.inMinutes > 0) {
        timeText = '${diff.inMinutes} phút trước';
      } else {
        timeText = 'Vừa xong';
      }
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        color: notification.isRead ? Colors.transparent : theme.primaryColor.withOpacity(0.05),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          color: notification.isRead ? Colors.black87 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
