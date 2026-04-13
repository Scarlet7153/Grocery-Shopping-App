package com.grocery.server.user.dto.response;

import com.grocery.server.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: UserListResponse
 * Mục đích: Response đơn giản để hiển thị danh sách users (cho admin)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserListResponse {

    private Long id;
    private String phoneNumber;
    private String fullName;
    private String role;
    private String status;
    private String avatarUrl;

    /**
     * Chuyển đổi từ Entity sang DTO
     */
    public static UserListResponse fromEntity(User user) {
        return UserListResponse.builder()
                .id(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole().name())
                .status(user.getStatus().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
}
