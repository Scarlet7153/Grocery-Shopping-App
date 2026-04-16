package com.grocery.server.review.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO: ReviewResponse
 * Mô tả: Response chứa thông tin chi tiết đánh giá
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewResponse {

    /**
     * ID đánh giá
     */
    private Long id;

    /**
     * ID đơn hàng
     */
    private Long orderId;

    /**
     * ID người đánh giá
     */
    private Long reviewerId;

    /**
     * Tên người đánh giá
     */
    private String reviewerName;

    /**
     * ID cửa hàng được đánh giá
     */
    private Long storeId;

    /**
     * Tên cửa hàng được đánh giá
     */
    private String storeName;

    /**
     * Điểm đánh giá (1-5 sao)
     */
    private Integer rating;

    /**
     * Nội dung bình luận
     */
    private String comment;

    /**
     * Phản hồi từ cửa hàng
     */
    private String storeReply;

    /**
     * Thời gian phản hồi từ cửa hàng
     */
    private LocalDateTime storeReplyAt;

    /**
     * Thời gian tạo đánh giá
     */
    private LocalDateTime createdAt;
}
