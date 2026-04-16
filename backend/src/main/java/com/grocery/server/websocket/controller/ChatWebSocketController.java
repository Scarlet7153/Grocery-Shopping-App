package com.grocery.server.websocket.controller;

import com.grocery.server.chat.dto.MessageResponse;
import com.grocery.server.chat.dto.SendMessageRequest;
import com.grocery.server.chat.service.ChatService;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SubscribeMapping;
import org.springframework.stereotype.Controller;

import java.security.Principal;

/**
 * Controller: ChatWebSocketController
 * Mục đích: Xử lý WebSocket messages cho chat real-time
 * Phase: 6 - Chat WebSocket
 *
 * Endpoints:
 * - SUB /topic/chat/conversation/{conversationId} : Nhận tin nhắn mới trong cuộc trò chuyện
 * - SUB /topic/chat/conversations/{userId} : Nhận cập nhật danh sách cuộc trò chuyện
 * - APP /chat/send : Gửi tin nhắn
 */
@Controller
@RequiredArgsConstructor
@Slf4j
public class ChatWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatService chatService;
    private final UserRepository userRepository;

    /**
     * Subscribe để nhận tin nhắn mới trong một cuộc trò chuyện
     * Khi client subscribe vào /topic/chat/conversation/{conversationId},
     * server sẽ gửi tin nhắn mới đến destination này
     */
    @SubscribeMapping("/chat/conversation/{conversationId}")
    public void subscribeToConversation(@DestinationVariable String conversationId, Principal principal) {
        log.info("User {} subscribed to conversation {}", principal.getName(), conversationId);
    }

    /**
     * Subscribe để nhận cập nhật danh sách cuộc trò chuyện
     */
    @SubscribeMapping("/chat/conversations/{userId}")
    public void subscribeToConversationList(@DestinationVariable Long userId, Principal principal) {
        log.info("User {} subscribed to conversation list", principal.getName());
    }

    /**
     * Xử lý gửi tin nhắn qua WebSocket
     * Client gửi message đến /app/chat/send
     * Server lưu vào DB, sau đó broadcast đến tất cả subscribers
     */
    @MessageMapping("/chat/send")
    public void handleSendMessage(
            @Payload SendMessageRequest request,
            Principal principal) {

        Long userId = getUserId(principal);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        log.info("WebSocket: User {} sending message in conversation {}",
                userId, request.getConversationId());

        // Lưu tin nhắn vào database
        MessageResponse message = chatService.sendMessage(userId, request);

        // Broadcast tin nhắn đến tất cả clients đang subscribe cuộc trò chuyện này
        messagingTemplate.convertAndSend(
                "/topic/chat/conversation/" + request.getConversationId(),
                message
        );

        // Cập nhật danh sách cuộc trò chuyện cho cả shipper và customer
        messagingTemplate.convertAndSend(
                "/topic/chat/conversations/" + message.getSenderId(),
                "update"
        );

        // Gửi đến người nhận (nếu đang online)
        String targetUserId = request.getSenderType().equals("SHIPPER")
                ? String.valueOf(getConversationCustomerId(request.getConversationId()))
                : String.valueOf(getConversationShipperId(request.getConversationId()));

        messagingTemplate.convertAndSend(
                "/topic/chat/conversations/" + targetUserId,
                "update"
        );
    }

    /**
     * Xử lý đánh dấu tin nhắn đã đọc qua WebSocket
     */
    @MessageMapping("/chat/read")
    public void handleMarkAsRead(
            @Payload MarkAsReadRequest request,
            Principal principal) {

        Long userId = getUserId(principal);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        log.info("WebSocket: User {} marking messages as read in conversation {}",
                userId, request.getConversationId());

        chatService.markMessagesAsRead(request.getConversationId(), userId, user.getRole().name());

        // Thông báo cho sender biết tin nhắn đã được đọc
        messagingTemplate.convertAndSend(
                "/topic/chat/conversation/" + request.getConversationId() + "/read",
                userId
        );
    }

    private Long getUserId(Principal principal) {
        String phone = principal.getName();
        User user = userRepository.findByPhoneNumber(phone)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        return user.getId();
    }

    private Long getConversationShipperId(String conversationId) {
        return chatService.getConversationById(conversationId).getShipperId();
    }

    private Long getConversationCustomerId(String conversationId) {
        return chatService.getConversationById(conversationId).getCustomerId();
    }

    @lombok.Data
    public static class MarkAsReadRequest {
        private String conversationId;
    }
}