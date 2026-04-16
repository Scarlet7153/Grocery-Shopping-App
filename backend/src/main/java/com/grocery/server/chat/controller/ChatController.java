package com.grocery.server.chat.controller;

import com.grocery.server.chat.dto.ConversationResponse;
import com.grocery.server.chat.dto.MessageResponse;
import com.grocery.server.chat.dto.SendMessageRequest;
import com.grocery.server.chat.service.ChatService;
import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;
    private final UserRepository userRepository;

    @PostMapping("/conversations")
    @PreAuthorize("hasAnyRole('SHIPPER', 'CUSTOMER')")
    public ResponseEntity<ApiResponse<ConversationResponse>> createOrGetConversation(
            @RequestParam Long orderId,
            @RequestParam Long shipperId,
            Authentication authentication) {

        Long userId = getUserId(authentication);
        ConversationResponse response = chatService.getOrCreateConversation(orderId, shipperId, userId);
        return ResponseEntity.ok(ApiResponse.success("Conversation retrieved", response));
    }

    @GetMapping("/conversations")
    @PreAuthorize("hasAnyRole('SHIPPER', 'CUSTOMER')")
    public ResponseEntity<ApiResponse<List<ConversationResponse>>> getConversations(
            Authentication authentication) {

        Long userId = getUserId(authentication);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UnauthorizedException("User not found"));

        List<ConversationResponse> conversations;
        if (user.getRole() == User.UserRole.SHIPPER) {
            conversations = chatService.getConversationsForShipper(userId);
        } else if (user.getRole() == User.UserRole.CUSTOMER) {
            conversations = chatService.getConversationsForCustomer(userId);
        } else {
            throw new UnauthorizedException("Invalid user role for chat");
        }

        return ResponseEntity.ok(ApiResponse.success("Conversations retrieved", conversations));
    }

    @GetMapping("/conversations/{conversationId}")
    @PreAuthorize("hasAnyRole('SHIPPER', 'CUSTOMER')")
    public ResponseEntity<ApiResponse<ConversationResponse>> getConversation(
            @PathVariable String conversationId) {

        ConversationResponse response = chatService.getConversationById(conversationId);
        return ResponseEntity.ok(ApiResponse.success("Conversation retrieved", response));
    }

    @GetMapping("/conversations/{conversationId}/messages")
    @PreAuthorize("hasAnyRole('SHIPPER', 'CUSTOMER')")
    public ResponseEntity<ApiResponse<List<MessageResponse>>> getMessages(
            @PathVariable String conversationId,
            Authentication authentication) {

        Long userId = getUserId(authentication);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UnauthorizedException("User not found"));

        List<MessageResponse> messages = chatService.getMessages(conversationId);

        chatService.markMessagesAsRead(conversationId, userId, user.getRole().name());

        return ResponseEntity.ok(ApiResponse.success("Messages retrieved", messages));
    }

    @PostMapping("/messages")
    @PreAuthorize("hasAnyRole('SHIPPER', 'CUSTOMER')")
    public ResponseEntity<ApiResponse<MessageResponse>> sendMessage(
            @Valid @RequestBody SendMessageRequest request,
            Authentication authentication) {

        Long userId = getUserId(authentication);
        MessageResponse response = chatService.sendMessage(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Message sent", response));
    }

    private Long getUserId(Authentication authentication) {
        String phone = authentication.getName();
        User user = userRepository.findByPhoneNumber(phone)
                .orElseThrow(() -> new UnauthorizedException("User not found"));
        return user.getId();
    }
}
