package com.grocery.server.messaging.dto;

import com.grocery.server.order.entity.Order;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * DTO: OrderStatusChangedEvent
 * Mục đích: Event khi trạng thái đơn hàng thay đổi
 * Phase: 3 - Pub/Sub Messaging
 * 
 * Gửi đến: Customer, Store, Shipper liên quan đến đơn hàng
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderStatusChangedEvent implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Event metadata
    @Builder.Default
    private String eventType = "ORDER_STATUS_CHANGED";
    private Long timestamp;
    
    // Order info
    private Long orderId;
    private Long customerId;
    private Long storeId;
    private Long shipperId;
    
    // Status info
    private Order.OrderStatus oldStatus;
    private Order.OrderStatus newStatus;
    private String statusDescription;
    
    // Time info
    private LocalDateTime changedAt;
    
    // Optional: Reason for status change (e.g., cancellation reason)
    private String reason;
}
