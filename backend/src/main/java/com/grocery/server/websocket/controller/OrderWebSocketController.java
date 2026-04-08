package com.grocery.server.websocket.controller;

import com.grocery.server.messaging.dto.OrderAcceptedEvent;
import com.grocery.server.messaging.dto.OrderCreatedEvent;
import com.grocery.server.messaging.dto.OrderStatusChangedEvent;
import com.grocery.server.order.entity.Order;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SubscribeMapping;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.time.LocalDateTime;

/**
 * Controller: OrderWebSocketController
 * Mục đích: Xử lý WebSocket messages cho order operations
 * Phase: 5 - WebSocket Controllers
 * 
 * Endpoints:
 * - SUB /topic/orders/new : Nhận đơn hàng mới (cho shipper)
 * - SUB /topic/orders/{id} : Theo dõi đơn hàng cụ thể
 * - APP /orders/{id}/accept : Shipper nhận đơn
 * - APP /orders/{id}/status : Cập nhật trạng thái
 */
@Controller
@RequiredArgsConstructor
@Slf4j
public class OrderWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Subscribe để nhận thông tin đơn hàng hiện tại
     * Khi client subscribe vào /topic/orders/{orderId}, server trả về thông tin hiện tại
     */
    @SubscribeMapping("/orders/{orderId}")
    public OrderSubscriptionResponse subscribeToOrder(@DestinationVariable Long orderId, Principal principal) {
        log.info("User {} subscribed to order {}", principal.getName(), orderId);
        
        // TODO: Lấy thông tin order từ database
        return OrderSubscriptionResponse.builder()
                .orderId(orderId)
                .message("Subscribed to order " + orderId)
                .build();
    }

    /**
     * Broadcast đơn hàng mới đến các shipper gần đó
     * Được gọi từ OrderService khi có đơn hàng mới
     */
    public void broadcastNewOrder(OrderCreatedEvent event) {
        log.info("Broadcasting new order {} to nearby shippers", event.getOrderId());
        
        // Gửi đến tất cả shipper (filter vị trí ở client hoặc dùng user-specific)
        messagingTemplate.convertAndSend("/topic/orders/new", event);
        
        // Cũng có thể gửi đến từng shipper cụ thể dựa trên vị trí
        // messagingTemplate.convertAndSendToUser(shipperId, "/queue/orders/new", event);
    }

    /**
     * Xử lý khi shipper nhận đơn
     * Client gửi message đến /app/orders/{orderId}/accept
     */
    @MessageMapping("/orders/{orderId}/accept")
    @SendTo("/topic/orders/{orderId}")
    public OrderAcceptedEvent handleOrderAcceptance(
            @DestinationVariable Long orderId,
            @Payload OrderAcceptanceRequest request,
            Principal principal) {
        
        String shipperId = principal.getName();
        log.info("Shipper {} attempting to accept order {}", shipperId, orderId);
        
        // TODO: Validate và xử lý nhận đơn (sẽ implement trong OrderAcceptanceService)
        // - Kiểm tra order còn available không
        // - Distributed lock để tránh race condition
        // - Cập nhật database
        
        OrderAcceptedEvent event = OrderAcceptedEvent.builder()
                .orderId(orderId)
                .shipperId(Long.parseLong(shipperId))
                .acceptedAt(LocalDateTime.now())
                .build();
        
        // Broadcast đến tất cả clients theo dõi đơn hàng này
        return event;
    }

    /**
     * Cập nhật trạng thái đơn hàng
     * Client gửi message đến /app/orders/{orderId}/status
     */
    @MessageMapping("/orders/{orderId}/status")
    public void updateOrderStatus(
            @DestinationVariable Long orderId,
            @Payload OrderStatusUpdateRequest request,
            Principal principal) {
        
        log.info("User {} updating order {} status to {}", 
            principal.getName(), orderId, request.getNewStatus());
        
        // TODO: Validate và cập nhật trạng thái
        OrderStatusChangedEvent event = OrderStatusChangedEvent.builder()
                .orderId(orderId)
                .oldStatus(request.getOldStatus())
                .newStatus(request.getNewStatus())
                .changedAt(LocalDateTime.now())
                .reason(request.getReason())
                .build();
        
        // Broadcast status change
        messagingTemplate.convertAndSend("/topic/orders/" + orderId + "/status", event);
    }

    // ========== DTOs for WebSocket ==========
    
    @lombok.Data
    @lombok.Builder
    public static class OrderSubscriptionResponse {
        private Long orderId;
        private String message;
    }
    
    @lombok.Data
    public static class OrderAcceptanceRequest {
        private Long shipperId;
        private String notes;
    }
    
    @lombok.Data
    public static class OrderStatusUpdateRequest {
        private Order.OrderStatus oldStatus;
        private Order.OrderStatus newStatus;
        private String reason;
    }
}
