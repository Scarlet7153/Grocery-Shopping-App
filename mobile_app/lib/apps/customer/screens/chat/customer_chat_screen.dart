import 'package:flutter/material.dart';

import '../../../../core/services/chat_websocket_service.dart';
import '../../../../features/customer/home/data/chat_api.dart';
import '../../../../features/customer/home/data/chat_model.dart';
import '../../utils/customer_l10n.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({
    super.key,
    required this.conversationId,
    required this.shipperName,
    required this.orderId,
  });

  final String conversationId;
  final String shipperName;
  final int orderId;

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final ChatApi _chatApi = ChatApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initWebSocket();
  }

  void _initWebSocket() {
    final wsService = ChatWebSocketService.instance;

    wsService.onMessageReceived = (message) {
      if (message.conversationId == widget.conversationId) {
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      }
    };

    wsService.connect();
    wsService.subscribeToConversation(widget.conversationId);
  }

  @override
  void dispose() {
    ChatWebSocketService.instance
        .unsubscribeFromConversation(widget.conversationId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatApi.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.tr(
            vi: 'Không thể tải tin nhắn',
            en: 'Unable to load messages',
          );
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final wsService = ChatWebSocketService.instance;
      if (wsService.isConnected) {
        wsService.sendMessage(
          conversationId: widget.conversationId,
          senderType: 'CUSTOMER',
          content: content,
        );
        setState(() => _sending = false);
      } else {
        final message = await _chatApi.sendMessage(
          conversationId: widget.conversationId,
          content: content,
        );
        if (mounted) {
          setState(() {
            _messages.add(message);
            _sending = false;
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(context.tr(
              vi: 'Không thể gửi tin nhắn',
              en: 'Unable to send message',
            )),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.delivery_dining,
                  size: 20, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.shipperName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    context.tr(vi: 'Shipper', en: 'Shipper'),
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Container(
        color: scheme.surfaceContainerLowest,
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: TextStyle(color: scheme.error)),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadMessages,
                                child: Text(
                                    context.tr(vi: 'Thử lại', en: 'Retry')),
                              ),
                            ],
                          ),
                        )
                      : _messages.isEmpty
                          ? Center(
                              child: Text(
                                context.tr(
                                  vi: 'Chưa có tin nhắn. Bắt đầu trò chuyện!',
                                  en: 'No messages yet. Start the conversation!',
                                ),
                                style:
                                    TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMe =
                                    message.senderType == SenderType.CUSTOMER;
                                return _MessageBubble(
                                  message: message,
                                  isMe: isMe,
                                );
                              },
                            ),
            ),
            _buildInputArea(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: context.tr(
                    vi: 'Nhập tin nhắn...',
                    en: 'Type a message...',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.send, color: scheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? scheme.onPrimary : scheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: isMe
                            ? scheme.onPrimary.withValues(alpha: 0.7)
                            : scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.read ? Icons.done_all : Icons.done,
                        size: 14,
                        color: scheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
