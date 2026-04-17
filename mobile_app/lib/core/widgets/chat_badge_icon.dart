import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/services/chat_unread_service.dart';

class ChatBadgeIcon extends StatefulWidget {
  final Color? color;
  final double size;

  const ChatBadgeIcon({Key? key, this.color, this.size = 24}) : super(key: key);

  @override
  State<ChatBadgeIcon> createState() => _ChatBadgeIconState();
}

class _ChatBadgeIconState extends State<ChatBadgeIcon> {
  @override
  void initState() {
    super.initState();
    ChatUnreadService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = widget.color ?? Theme.of(context).iconTheme.color;

    return ValueListenableBuilder<int>(
      valueListenable: ChatUnreadService.instance.unreadCount,
      builder: (context, count, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.chat, color: defaultColor, size: widget.size),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
