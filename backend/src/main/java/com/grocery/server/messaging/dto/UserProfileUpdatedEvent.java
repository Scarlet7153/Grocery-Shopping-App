package com.grocery.server.messaging.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * DTO: UserProfileUpdatedEvent
 * Mục đích: Event realtime khi thông tin hồ sơ người dùng thay đổi
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileUpdatedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    // Event metadata
    private String eventType = "USER_PROFILE_UPDATED";
    private Long timestamp;

    // User info
    private Long userId;
    private String phoneNumber;
    private String fullName;
    private String avatarUrl;
    private String address;

    // Time info
    private LocalDateTime updatedAt;
}
