package com.grocery.server.messaging.publisher;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

/**
 * Service: RedisMessagePublisher
 * Mục đích: Publish messages đến Redis Pub/Sub channels
 * Phase: 3 - Pub/Sub Messaging
 * 
 * Channels:
 * - order:* : Các events liên quan đến đơn hàng
 * - location:order:{id} : Location updates cho đơn hàng
 */
@Service
@Slf4j
public class RedisMessagePublisher {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public RedisMessagePublisher(ObjectMapper objectMapper, @Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.objectMapper = objectMapper;
        this.redisTemplate = redisTemplate;
        if (redisTemplate == null) {
            log.warn("Redis is disabled. RedisMessagePublisher will not publish any messages.");
        }
    }

    /**
     * Publish message đến Redis channel
     * 
     * @param channel Redis channel name
     * @param message Message object (sẽ được serialize thành JSON)
     */
    public void publish(String channel, Object message) {
        if (redisTemplate == null) {
            log.trace("Redis disabled, skipping publish to channel {}: {}", channel, message);
            return;
        }
        try {
            String jsonMessage = objectMapper.writeValueAsString(message);
            redisTemplate.convertAndSend(channel, jsonMessage);
            log.debug("Published message to channel [{}]: {}", channel, jsonMessage);
        } catch (JsonProcessingException e) {
            log.error("Error serializing message for channel [{}]: {}", channel, e.getMessage());
        }
    }

    /**
     * Publish message đến channel (đã là JSON string)
     * 
     * @param channel Redis channel name
     * @param jsonMessage JSON string message
     */
    public void publish(String channel, String jsonMessage) {
        if (redisTemplate == null) {
            log.trace("Redis disabled, skipping publish to channel {}: {}", channel, jsonMessage);
            return;
        }
        redisTemplate.convertAndSend(channel, jsonMessage);
        log.debug("Published message to channel [{}]: {}", channel, jsonMessage);
    }

    /**
     * Publish order event
     * 
     * @param eventType Loại event (created, accepted, status_changed)
     * @param orderId ID của đơn hàng
     * @param message Event message
     */
    public void publishOrderEvent(String eventType, Long orderId, Object message) {
        String channel = String.format("order:%s:%d", eventType, orderId);
        publish(channel, message);
    }

    /**
     * Publish location update
     * 
     * @param orderId ID của đơn hàng
     * @param locationUpdate Location update object
     */
    public void publishLocationUpdate(Long orderId, Object locationUpdate) {
        String channel = String.format("location:order:%d", orderId);
        publish(channel, locationUpdate);
    }
}
