package com.grocery.server.user.dto.response;

import com.grocery.server.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: StoreApprovalResponse
 * Mục đích: Response cho admin duyệt cửa hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreApprovalResponse {

    private Long userId;
    private String phoneNumber;
    private String fullName;
    private String status;
    private String avatarUrl;

    private Long storeId;
    private String storeName;
    private String storeAddress;
    private String storePhone;

    /**
     * Chuyển đổi từ Entity sang DTO
     */
    public static StoreApprovalResponse fromEntity(User user) {
        StoreApprovalResponse.StoreApprovalResponseBuilder builder = StoreApprovalResponse.builder()
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .status(user.getStatus().name())
                .avatarUrl(user.getAvatarUrl());

        if (user.getStore() != null) {
            builder.storeId(user.getStore().getId())
                    .storeName(user.getStore().getStoreName())
                    .storeAddress(user.getStore().getAddress())
                    .storePhone(user.getStore().getPhoneNumber());
        }

        return builder.build();
    }
}
