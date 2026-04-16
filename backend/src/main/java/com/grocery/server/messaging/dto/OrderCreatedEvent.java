package com.grocery.server.messaging.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO: OrderCreatedEvent
 * Mục đích: Event khi có đơn hàng mới được tạo
 * Phase: 3 - Pub/Sub Messaging
 * 
 * Gửi đến: Các shipper gần vị trí đặt hàng
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderCreatedEvent implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Event metadata
    @Builder.Default
    private String eventType = "ORDER_CREATED";
    private Long timestamp;
    
    // Order info
    private Long orderId;
    private Long customerId;
    private Long storeId;
    private String storeName;
    private BigDecimal totalAmount;
    private BigDecimal shippingFee;
    
    // Delivery info
    private String deliveryAddress;
    private Double deliveryLat;
    private Double deliveryLng;
    
    // Time info
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt; // Thờigian hết hạn để nhận đơn
}
