package com.grocery.server.config;

import com.grocery.server.websocket.interceptor.WebSocketAuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * Configuration: WebSocketConfig
 * Mục đích: Cấu hình WebSocket STOMP cho real-time communication
 * Phase: 2 - WebSocket STOMP Setup
 * 
 * STOMP Protocol:
 * - /app: Client gửi message đến server (application destination)
 * - /topic: Broadcast messages (pub/sub)
 * - /user: User-specific messages
 * - /queue: Point-to-point messages
 */
@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final WebSocketAuthInterceptor webSocketAuthInterceptor;

    /**
     * Cấu hình Message Broker
     * - enableSimpleBroker: Sử dụng in-memory broker cho /topic và /user
     * - setApplicationDestinationPrefixes: Client gửi message đến /app/**
     * - setUserDestinationPrefix: User-specific destinations
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Enable broker cho các destination prefixes
        config.enableSimpleBroker("/topic", "/queue", "/user");
        
        // Client gửi message đến server qua prefix này
        config.setApplicationDestinationPrefixes("/app");
        
        // User-specific messages prefix
        config.setUserDestinationPrefix("/user");
    }

    /**
     * Đăng ký STOMP endpoints
     * - /ws: WebSocket endpoint chính
     * - setAllowedOriginPatterns: Cho phép tất cả origins (có thể giới hạn sau)
     * - withSockJS: Fallback cho browsers không hỗ trợ WebSocket
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*") // Production: giới hạn origins cụ thể
                .withSockJS(); // Fallback mechanism
    }

    /**
     * Cấu hình inbound channel - Xác thực và phân quyền
     * - Thêm interceptor để validate JWT token khi kết nối
     */
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(webSocketAuthInterceptor);
    }
}
