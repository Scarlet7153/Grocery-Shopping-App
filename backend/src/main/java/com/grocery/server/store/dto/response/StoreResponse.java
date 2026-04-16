package com.grocery.server.store.dto.response;

import com.grocery.server.store.entity.Store;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Response: StoreResponse
 * Mục đích: Trả về thông tin chi tiết cửa hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreResponse {

    private Long id;
    private Long ownerId;
    private String ownerName;
    private String ownerPhone;
    private String storeName;
    private String address;
    private String imageUrl;
    private LocalDateTime createdAt;
    private Boolean isOpen;
    private Double averageRating;
    private Long totalReviews;

    /**
     * Chuyển từ Store entity sang StoreResponse DTO
     */
    public static StoreResponse fromEntity(Store store, Double averageRating, Long totalReviews) {
        return StoreResponse.builder()
                .id(store.getId())
                .ownerId(store.getOwner().getId())
                .ownerName(store.getOwner().getFullName())
                .ownerPhone(store.getOwner().getPhoneNumber())
                .storeName(store.getStoreName())
                .address(store.getAddress())
                .imageUrl(store.getImageUrl())
                .createdAt(store.getCreatedAt())
                .isOpen(store.getIsOpen())
                .averageRating(averageRating)
                .totalReviews(totalReviews)
                .build();
    }
}
