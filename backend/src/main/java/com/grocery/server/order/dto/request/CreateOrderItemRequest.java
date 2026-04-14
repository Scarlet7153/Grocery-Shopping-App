package com.grocery.server.order.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: CreateOrderItemRequest
 * Mô tả: Chi tiết một sản phẩm trong đơn hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateOrderItemRequest {

    /**
     * ID của ProductUnitMapping (variant bán cụ thể, ví dụ: 300g, 500g, 1kg)
     * Hỗ trợ alias productUnitId để tương thích payload cũ.
     */
    @NotNull(message = "ID biến thể sản phẩm không được để trống")
    @JsonAlias({"productUnitId"})
    private Long productUnitMappingId;

    /**
     * Số lượng mua
     */
    @NotNull(message = "Số lượng không được để trống")
    @Positive(message = "Số lượng phải lớn hơn 0")
    private Integer quantity;
}
