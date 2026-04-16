package com.grocery.server.store.dto.response;

import com.grocery.server.store.entity.Store;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Response: StoreListResponse
 * Mục đích: Trả về danh sách cửa hàng (rút gọn thông tin)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreListResponse {

    private Long id;
    private String storeName;
    private String address;
    private Boolean isOpen;
    private String ownerName;
    private String imageUrl;
    private Double averageRating;
    private Long totalReviews;

    /**
     * Chuyển từ Store entity sang StoreListResponse DTO
     */
    public static StoreListResponse fromEntity(Store store, Double averageRating, Long totalReviews) {
        return StoreListResponse.builder()
                .id(store.getId())
                .storeName(store.getStoreName())
                .address(store.getAddress())
                .isOpen(store.getIsOpen())
                .ownerName(store.getOwner().getFullName())
                .imageUrl(store.getImageUrl())
                .averageRating(averageRating)
                .totalReviews(totalReviews)
                .build();
    }
}
