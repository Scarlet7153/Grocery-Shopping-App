package com.grocery.server.order.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO: OrderItemResponse
 * Mô tả: Thông tin chi tiết một sản phẩm trong đơn hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItemResponse {

    /**
     * ID order item
     */
    private Long id;

    /**
     * ID sản phẩm
     */
    private Long productId;

    /**
     * Tên sản phẩm
     */
    private String productName;

    /**
     * Ảnh sản phẩm
     */
    private String productImageUrl;

    /**
     * Tên đơn vị (ví dụ: "Gói 300g", "Khay 1kg")
     */
    private String unitName;

    /**
     * Đơn giá tại thời điểm đặt hàng
     */
    private BigDecimal unitPrice;

    /**
     * Số lượng mua
     */
    private BigDecimal quantity;

    /**
     * Thành tiền (unitPrice * quantity)
     */
    private BigDecimal subtotal;
}
