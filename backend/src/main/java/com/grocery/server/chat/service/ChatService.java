package com.grocery.server.chat.service;

import com.grocery.server.chat.document.Conversation;
import com.grocery.server.chat.document.Message;
import com.grocery.server.chat.dto.ConversationResponse;
import com.grocery.server.chat.dto.MessageResponse;
import com.grocery.server.chat.dto.SendMessageRequest;
import com.grocery.server.chat.repository.ConversationRepository;
import com.grocery.server.chat.repository.MessageRepository;
import com.grocery.server.order.entity.Order;
import com.grocery.server.order.repository.OrderRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatService {

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    public ConversationResponse getOrCreateConversation(Long orderId, Long shipperId, Long customerId) {
        var existing = conversationRepository.findByOrderId(orderId);
        if (existing.isPresent()) {
            return toConversationResponse(existing.get());
        }

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));
        User shipper = userRepository.findById(shipperId)
                .orElseThrow(() -> new IllegalArgumentException("Shipper not found"));
        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found"));

        Conversation conv = Conversation.builder()
                .orderId(orderId)
                .shipperId(shipperId)
                .customerId(customerId)
                .shipperName(shipper.getFullName())
                .customerName(customer.getFullName())
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Conversation saved = conversationRepository.save(conv);
        log.info("Created conversation {} for order {}", saved.getId(), orderId);
        return toConversationResponse(saved);
    }

    public List<ConversationResponse> getConversationsForShipper(Long shipperId) {
        return conversationRepository.findByShipperIdOrderByUpdatedAtDesc(shipperId)
                .stream()
                .map(this::toConversationResponse)
                .collect(Collectors.toList());
    }

    public List<ConversationResponse> getConversationsForCustomer(Long customerId) {
        return conversationRepository.findByCustomerIdOrderByUpdatedAtDesc(customerId)
                .stream()
                .map(this::toConversationResponse)
                .collect(Collectors.toList());
    }

    public MessageResponse sendMessage(Long senderId, SendMessageRequest request) {
        Conversation conv = conversationRepository.findById(request.getConversationId())
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));

        Message.SenderType senderType = Message.SenderType.valueOf(request.getSenderType());

        Message message = Message.builder()
                .conversationId(request.getConversationId())
                .senderId(senderId)
                .senderType(senderType)
                .content(request.getContent())
                .timestamp(LocalDateTime.now())
                .read(false)
                .build();

        Message saved = messageRepository.save(message);

        conv.setLastMessage(request.getContent());
        conv.setLastMessageAt(LocalDateTime.now());
        conv.setUpdatedAt(LocalDateTime.now());
        conversationRepository.save(conv);

        log.info("Message sent in conversation {} by {}", request.getConversationId(), senderType);
        return toMessageResponse(saved);
    }

    public List<MessageResponse> getMessages(String conversationId) {
        return messageRepository.findByConversationIdOrderByTimestampAsc(conversationId)
                .stream()
                .map(this::toMessageResponse)
                .collect(Collectors.toList());
    }

    public void markMessagesAsRead(String conversationId, Long userId, String userType) {
        List<Message> messages = messageRepository.findByConversationIdOrderByTimestampAsc(conversationId);
        Message.SenderType oppositeType = userType.equals("SHIPPER")
                ? Message.SenderType.CUSTOMER
                : Message.SenderType.SHIPPER;

        for (Message msg : messages) {
            if (!msg.isRead() && msg.getSenderType() == oppositeType) {
                msg.setRead(true);
                messageRepository.save(msg);
            }
        }
    }

    public ConversationResponse getConversationById(String conversationId) {
        Conversation conv = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));
        return toConversationResponse(conv);
    }

    private ConversationResponse toConversationResponse(Conversation conv) {
        long unread = messageRepository.countByConversationIdAndReadFalseAndSenderTypeNot(
                conv.getId(),
                conv.getShipperId() != null ? Message.SenderType.SHIPPER : Message.SenderType.CUSTOMER
        );

        return ConversationResponse.builder()
                .id(conv.getId())
                .orderId(conv.getOrderId())
                .shipperId(conv.getShipperId())
                .customerId(conv.getCustomerId())
                .shipperName(conv.getShipperName())
                .customerName(conv.getCustomerName())
                .lastMessage(conv.getLastMessage())
                .lastMessageAt(conv.getLastMessageAt())
                .createdAt(conv.getCreatedAt())
                .unreadCount(unread)
                .build();
    }

    private MessageResponse toMessageResponse(Message msg) {
        return MessageResponse.builder()
                .id(msg.getId())
                .conversationId(msg.getConversationId())
                .senderId(msg.getSenderId())
                .senderType(msg.getSenderType())
                .content(msg.getContent())
                .timestamp(msg.getTimestamp())
                .read(msg.isRead())
                .build();
    }
}
