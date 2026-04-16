package com.grocery.server.messaging.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * DTO: OrderAcceptedEvent
 * Mục đích: Event khi shipper nhận đơn hàng thành công
 * Phase: 3 - Pub/Sub Messaging
 * 
 * Gửi đến: Tất cả clients đang theo dõi đơn hàng này
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderAcceptedEvent implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Event metadata
    @Builder.Default
    private String eventType = "ORDER_ACCEPTED";
    private Long timestamp;
    
    // Order info
    private Long orderId;
    private Long customerId;
    private Long storeId;
    
    // Shipper info
    private Long shipperId;
    private String shipperName;
    private String shipperPhone;
    
    // Time info
    private LocalDateTime acceptedAt;
}
