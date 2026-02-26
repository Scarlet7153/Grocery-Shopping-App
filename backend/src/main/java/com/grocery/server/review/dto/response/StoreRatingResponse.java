package com.grocery.server.review.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: StoreRatingResponse
 * Mô tả: Response chứa thông tin điểm đánh giá trung bình của cửa hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreRatingResponse {

    /**
     * ID cửa hàng
     */
    private Long storeId;

    /**
     * Tên cửa hàng
     */
    private String storeName;

    /**
     * Điểm trung bình (1-5)
     */
    private Double averageRating;

    /**
     * Tổng số đánh giá
     */
    private Long totalReviews;
}
