package com.grocery.server.review.dto.request;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: CreateReviewRequest
 * Mô tả: Request để tạo đánh giá mới
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateReviewRequest {

    /**
     * ID đơn hàng
     */
    @NotNull(message = "Order ID is required")
    private Long orderId;

    /**
     * Điểm đánh giá (1-5 sao)
     */
    @NotNull(message = "Rating is required")
    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    private Integer rating;

    /**
     * Nội dung bình luận (không bắt buộc)
     */
    @Size(max = 1000, message = "Comment must not exceed 1000 characters")
    private String comment;
}
