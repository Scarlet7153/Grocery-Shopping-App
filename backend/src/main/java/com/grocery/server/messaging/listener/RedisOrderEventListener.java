package com.grocery.server.messaging.listener;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.grocery.server.messaging.dto.OrderAcceptedEvent;
import com.grocery.server.messaging.dto.OrderCreatedEvent;
import com.grocery.server.messaging.dto.OrderStatusChangedEvent;
import com.grocery.server.messaging.dto.UserProfileUpdatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

/**
 * Listener: RedisOrderEventListener
 * Mục đích: Lắng nghe events từ Redis và forward đến WebSocket clients
 * Phase: 3 - Pub/Sub Messaging
 * 
 * Đây là cầu nối giữa Redis Pub/Sub và WebSocket:
 * - Nhiều server instances publish events đến Redis
 * - Listener nhận events và broadcast đến WebSocket subscribers
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RedisOrderEventListener implements MessageListener {

    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper;

    @Override
    public void onMessage(Message message, byte[] pattern) {
        String channel = new String(message.getChannel());
        String body = new String(message.getBody());
        
        log.debug("Received message from channel [{}]: {}", channel, body);
        
        try {
            if (channel.startsWith("order:created:")) {
                handleOrderCreated(body);
            } else if (channel.startsWith("order:accepted:")) {
                handleOrderAccepted(body);
            } else if (channel.startsWith("order:status:")) {
                handleOrderStatusChanged(body);
            } else if (channel.startsWith("location:order:")) {
                handleLocationUpdate(channel, body);
            } else if (channel.startsWith("user:profile:")) {
                handleUserProfileUpdated(body);
            }
        } catch (Exception e) {
            log.error("Error processing message from channel [{}]: {}", channel, e.getMessage());
        }
    }
    
    /**
     * Xử lý order created event
     * Broadcast đến shipper gần đó
     */
    private void handleOrderCreated(String body) throws Exception {
        OrderCreatedEvent event = objectMapper.readValue(body, OrderCreatedEvent.class);
        log.info("Order created event: orderId={}", event.getOrderId());
        
        // Broadcast đến tất cả shipper (sẽ filter ở client hoặc dùng user-specific)
        messagingTemplate.convertAndSend("/topic/orders/new", event);
    }
    
    /**
     * Xử lý order accepted event
     * Thông báo đến customer và store
     */
    private void handleOrderAccepted(String body) throws Exception {
        OrderAcceptedEvent event = objectMapper.readValue(body, OrderAcceptedEvent.class);
        log.info("Order accepted event: orderId={}, shipperId={}", 
            event.getOrderId(), event.getShipperId());
        
        // Broadcast đến tất cả clients theo dõi đơn hàng này
        messagingTemplate.convertAndSend("/topic/orders/" + event.getOrderId(), event);

        // Broadcast kênh chung để client có thể refresh danh sách đơn theo thời gian thực
        messagingTemplate.convertAndSend("/topic/orders/accepted", event);
        
        // Thông báo đến customer cụ thể
        messagingTemplate.convertAndSendToUser(
            event.getCustomerId().toString(),
            "/queue/orders/accepted",
            event
        );
    }
    
    /**
     * Xử lý order status changed event
     */
    private void handleOrderStatusChanged(String body) throws Exception {
        OrderStatusChangedEvent event = objectMapper.readValue(body, OrderStatusChangedEvent.class);
        log.info("Order status changed: orderId={}, {} -> {}",
            event.getOrderId(), event.getOldStatus(), event.getNewStatus());
        
        // Broadcast đến tất cả clients theo dõi đơn hàng
        messagingTemplate.convertAndSend("/topic/orders/" + event.getOrderId() + "/status", event);

        // Broadcast kênh chung để dashboard shipper refresh real-time
        messagingTemplate.convertAndSend("/topic/orders/status", event);
    }
    
    /**
     * Xử lý location update
     */
    private void handleLocationUpdate(String channel, String body) throws Exception {
        // Extract orderId từ channel "location:order:{id}"
        Long orderId = extractOrderId(channel);
        
        if (orderId != null) {
            log.debug("Location update for order {}", orderId);
            
            // Broadcast location đến tất cả clients theo dõi
            messagingTemplate.convertAndSend("/topic/location/" + orderId, body);
        }
    }

    /**
     * Xử lý user profile updated event
     */
    private void handleUserProfileUpdated(String body) throws Exception {
        UserProfileUpdatedEvent event = objectMapper.readValue(body, UserProfileUpdatedEvent.class);
        log.info("User profile updated event: userId={}", event.getUserId());

        // User-specific queue (khuyến nghị cho dữ liệu cá nhân)
        messagingTemplate.convertAndSendToUser(
            event.getPhoneNumber(),
            "/queue/profile",
            event
        );

        // Topic theo userId để hỗ trợ các client tự quản lý subscribe
        messagingTemplate.convertAndSend("/topic/users/profile/" + event.getUserId(), event);
    }
    
    /**
     * Extract orderId từ channel name
     */
    private Long extractOrderId(String channel) {
        try {
            String[] parts = channel.split(":");
            if (parts.length >= 3) {
                return Long.parseLong(parts[2]);
            }
        } catch (NumberFormatException e) {
            log.warn("Cannot extract orderId from channel: {}", channel);
        }
        return null;
    }
}
