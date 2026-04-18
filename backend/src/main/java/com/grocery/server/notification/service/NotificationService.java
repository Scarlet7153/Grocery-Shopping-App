package com.grocery.server.notification.service;

import com.grocery.server.notification.document.Notification;
import com.grocery.server.notification.dto.NotificationResponse;
import com.grocery.server.notification.dto.UnreadCountResponse;
import com.grocery.server.notification.repository.NotificationRepository;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final MongoTemplate mongoTemplate;   // Cần cho markAllAsRead

    /**
     * Tạo notification, lưu vào MongoDB và push real-time qua WebSocket.
     * Principal của WS là phone number (khớp với ChatService).
     */
    public NotificationResponse createAndSend(
            Long recipientId,
            String type,
            String title,
            String body,
            Long referenceId,
            String referenceType) {

        User recipient = userRepository.findById(recipientId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        Notification notification = Notification.builder()
                .recipientId(recipientId)
                .recipientPhone(recipient.getPhoneNumber())  // Lưu phone để gửi WS
                .type(type)
                .title(title)
                .body(body)
                .referenceId(referenceId)
                .referenceType(referenceType)
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();

        Notification saved = notificationRepository.save(notification);
        log.info("Tạo notification [{}] cho user #{} ({}): {}", type, recipientId, recipient.getPhoneNumber(), title);

        NotificationResponse response = mapToResponse(saved);

        // Push real-time đến user — dùng PHONE NUMBER làm principal (khớp ChatService)
        messagingTemplate.convertAndSendToUser(
                recipient.getPhoneNumber(),
                "/queue/notifications",
                response
        );

        // Cập nhật badge count
        long unreadCount = notificationRepository.countByRecipientIdAndIsReadFalse(recipientId);
        messagingTemplate.convertAndSendToUser(
                recipient.getPhoneNumber(),
                "/queue/notifications/count",
                unreadCount
        );

        return response;
    }

    /** Lấy tất cả thông báo của user (mới nhất trước) */
    public List<NotificationResponse> getNotifications(Long userId) {
        return notificationRepository
                .findByRecipientIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /** Đếm thông báo chưa đọc */
    public UnreadCountResponse getUnreadCount(Long userId) {
        long count = notificationRepository.countByRecipientIdAndIsReadFalse(userId);
        return new UnreadCountResponse(count);
    }

    /** Đánh dấu 1 thông báo đã đọc — nhận String id (MongoDB ObjectId) */
    public NotificationResponse markAsRead(String notificationId, Long userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông báo"));

        if (!notification.getRecipientId().equals(userId)) {
            throw new UnauthorizedException("Bạn không có quyền thao tác thông báo này");
        }

        notification.setRead(true);
        return mapToResponse(notificationRepository.save(notification));
    }

    /** Đánh dấu tất cả đã đọc — dùng MongoTemplate.updateMulti() */
    public void markAllAsRead(Long userId) {
        Query query = Query.query(Criteria.where("recipientId").is(userId).and("isRead").is(false));
        Update update = Update.update("isRead", true);
        mongoTemplate.updateMulti(query, update, Notification.class);
        log.info("Đánh dấu tất cả thông báo đã đọc cho user #{}", userId);
    }

    /** Xóa 1 thông báo */
    public void deleteNotification(String notificationId, Long userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông báo"));
        if (!notification.getRecipientId().equals(userId)) {
            throw new UnauthorizedException("Bạn không có quyền xóa thông báo này");
        }
        notificationRepository.delete(notification);
    }

    private NotificationResponse mapToResponse(Notification n) {
        return NotificationResponse.builder()
                .id(n.getId())
                .recipientId(n.getRecipientId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .referenceId(n.getReferenceId())
                .referenceType(n.getReferenceType())
                .isRead(n.isRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
