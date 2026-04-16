package com.grocery.server.review.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: StoreReplyRequest
 * Mô tả: Request body cho phản hồi đánh giá từ cửa hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StoreReplyRequest {

    @NotBlank(message = "Reply content cannot be blank")
    @Size(max = 500, message = "Reply must not exceed 500 characters")
    private String reply;
}
