package com.grocery.server.order.dto.response;

import com.grocery.server.order.entity.Order.OrderStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO: OrderResponse
 * Mô tả: Thông tin đầy đủ của một đơn hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderResponse {

    /**
     * ID đơn hàng
     */
    private Long id;

    /**
     * ID khách hàng
     */
    private Long customerId;

    /**
     * Tên khách hàng
     */
    private String customerName;

    /**
     * Số điện thoại khách hàng
     */
    private String customerPhone;

    /**
     * ID cửa hàng
     */
    private Long storeId;

    /**
     * Tên cửa hàng
     */
    private String storeName;

    /**
     * Địa chỉ cửa hàng
     */
    private String storeAddress;

    /**
     * ID tài xế (null nếu chưa có ai nhận)
     */
    private Long shipperId;

    /**
     * Tên tài xế
     */
    private String shipperName;

    /**
     * Số điện thoại tài xế
     */
    private String shipperPhone;

    /**
     * Trạng thái đơn hàng
     */
    private OrderStatus status;

    /**
     * Tổng tiền hàng hóa (VNĐ)
     */
    private BigDecimal totalAmount;

    /**
     * Phí vận chuyển (VNĐ)
     */
    private BigDecimal shippingFee;

    /**
     * Tổng thanh toán (totalAmount + shippingFee)
     */
    private BigDecimal grandTotal;

    /**
     * Địa chỉ giao hàng
     */
    private String deliveryAddress;

    /**
     * Ảnh chứng minh giao hàng (nếu có)
     */
    private String podImageUrl;

    /**
     * Lý do hủy đơn (nếu có)
     */
    private String cancelReason;

    /**
     * Thời gian đặt hàng
     */
    private LocalDateTime createdAt;

    /**
     * Danh sách sản phẩm trong đơn
     */
    private List<OrderItemResponse> items;

    /**
     * Phương thức thanh toán (COD, MOMO, VNPAY)
     */
    private String paymentMethod;
}
