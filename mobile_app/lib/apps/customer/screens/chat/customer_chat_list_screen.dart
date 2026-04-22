import 'package:flutter/material.dart';

import '../../../../core/services/chat_websocket_service.dart';
import '../../../../features/customer/home/data/chat_api.dart';
import '../../../../features/customer/home/data/chat_model.dart';
import '../../shared/customer_state_view.dart';
import '../../utils/customer_l10n.dart';
import 'customer_chat_screen.dart';

class CustomerChatListScreen extends StatefulWidget {
  const CustomerChatListScreen({super.key});

  @override
  State<CustomerChatListScreen> createState() => _CustomerChatListScreenState();
}

class _CustomerChatListScreenState extends State<CustomerChatListScreen> {
  final ChatApi _chatApi = ChatApi();

  List<ConversationModel> _conversations = [];
  bool _loading = true;
  String? _error;

  late final ConversationUpdateCallback _conversationUpdatedListener;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _initWebSocket();
  }

  void _initWebSocket() {
    final wsService = ChatWebSocketService.instance;

    _conversationUpdatedListener = () {
      if (mounted) {
        _loadConversations();
      }
    };

    wsService.addConversationUpdateListener(_conversationUpdatedListener);

    wsService.connect();
    wsService.subscribeToConversationList();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final conversations = await _chatApi.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.tr(
            vi: 'Không thể tải cuộc trò chuyện',
            en: 'Unable to load conversations',
          );
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    final wsService = ChatWebSocketService.instance;
    wsService.removeConversationUpdateListener(_conversationUpdatedListener);
    wsService.unsubscribeFromConversationList();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(vi: 'Chat', en: 'Chat')),
      ),
      body: Container(
        color: scheme.surfaceContainerLowest,
        child: _loading
            ? CustomerStateView.loading(compact: true)
            : _error != null
                ? CustomerStateView.error(
                    compact: true,
                    message: _error!,
                    onAction: _loadConversations,
                  )
                : _conversations.isEmpty
                    ? CustomerStateView.empty(
                        compact: true,
                        title: context.tr(
                            vi: 'Chưa có tin nhắn', en: 'No messages yet'),
                        message: context.tr(
                          vi: 'Khi có đơn hàng đang giao, bạn có thể chat với shipper.',
                          en: 'When you have orders being delivered, you can chat with the shipper.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final conv = _conversations[index];
                            return _ConversationTile(
                              conversation: conv,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerChatScreen(
                                      conversationId: conv.id,
                                      shipperName: conv.shipperName,
                                      shipperAvatar: conv.shipperAvatar,
                                      orderId: conv.orderId,
                                    ),
                                  ),
                                );
                                _loadConversations();
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: conversation.shipperAvatar != null && conversation.shipperAvatar!.isNotEmpty
                    ? NetworkImage(conversation.shipperAvatar!)
                    : null,
                child: conversation.shipperAvatar == null || conversation.shipperAvatar!.isEmpty
                    ? Icon(Icons.delivery_dining,
                        color: scheme.onPrimaryContainer)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.shipperName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.tr(vi: 'Đơn hàng', en: 'Order')} #${conversation.orderId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                    if (conversation.lastMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (conversation.lastMessageAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  _formatTime(conversation.lastMessageAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}
