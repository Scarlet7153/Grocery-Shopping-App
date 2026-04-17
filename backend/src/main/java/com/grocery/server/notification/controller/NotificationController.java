package com.grocery.server.notification.controller;

import com.grocery.server.notification.dto.NotificationResponse;
import com.grocery.server.notification.dto.UnreadCountResponse;
import com.grocery.server.notification.service.NotificationService;
import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    /** GET /notifications */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> getNotifications(
            Authentication authentication) {
        Long userId = getUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(
            "Lấy thông báo thành công",
            notificationService.getNotifications(userId)
        ));
    }

    /** GET /notifications/unread-count */
    @GetMapping("/unread-count")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<UnreadCountResponse>> getUnreadCount(
            Authentication authentication) {
        Long userId = getUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(
            "Lấy số thông báo chưa đọc thành công",
            notificationService.getUnreadCount(userId)
        ));
    }

    /**
     * PUT /notifications/{id}/read
     * id là MongoDB ObjectId (String), VD: "6621f3abc12345678901abcd"
     */
    @PutMapping("/{id}/read")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<NotificationResponse>> markAsRead(
            @PathVariable String id,          // String, không phải Long!
            Authentication authentication) {
        Long userId = getUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(
            "Đánh dấu đã đọc thành công",
            notificationService.markAsRead(id, userId)
        ));
    }

    /** PUT /notifications/read-all */
    @PutMapping("/read-all")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(Authentication authentication) {
        Long userId = getUserId(authentication);
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.success("Đã đánh dấu tất cả là đã đọc", null));
    }

    /**
     * DELETE /notifications/{id}
     * id là MongoDB ObjectId (String)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> deleteNotification(
            @PathVariable String id,           // String, không phải Long!
            Authentication authentication) {
        Long userId = getUserId(authentication);
        notificationService.deleteNotification(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Xóa thông báo thành công", null));
    }

    private Long getUserId(Authentication authentication) {
        String phoneNumber = authentication.getName();
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UnauthorizedException("User không tồn tại"));
        return user.getId();
    }
}
