package com.grocery.server.review.dto.request;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: UpdateReviewRequest
 * Mô tả: Request để cập nhật đánh giá
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateReviewRequest {

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
