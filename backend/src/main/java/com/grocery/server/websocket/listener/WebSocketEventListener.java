package com.grocery.server.websocket.listener;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;
import org.springframework.web.socket.messaging.SessionSubscribeEvent;
import org.springframework.web.socket.messaging.SessionUnsubscribeEvent;

import java.security.Principal;

/**
 * Listener: WebSocketEventListener
 * Mục đích: Theo dõi các sự kiện WebSocket (connect, disconnect, subscribe)
 * Phase: 2 - WebSocket Monitoring
 * 
 * Các sự kiện:
 * - SessionConnectedEvent: Client kết nối thành công
 * - SessionDisconnectEvent: Client ngắt kết nối
 * - SessionSubscribeEvent: Client subscribe vào một topic
 * - SessionUnsubscribeEvent: Client unsubscribe
 */
@Component
@Slf4j
public class WebSocketEventListener {

    @EventListener
    public void handleSessionConnected(SessionConnectedEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        Principal user = headerAccessor.getUser();
        String sessionId = headerAccessor.getSessionId();
        
        if (user != null) {
            log.info("WebSocket CONNECTED - User: {}, Session: {}", user.getName(), sessionId);
        } else {
            log.info("WebSocket CONNECTED - Anonymous, Session: {}", sessionId);
        }
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        Principal user = headerAccessor.getUser();
        String sessionId = headerAccessor.getSessionId();
        
        if (user != null) {
            log.info("WebSocket DISCONNECTED - User: {}, Session: {}", user.getName(), sessionId);
        } else {
            log.info("WebSocket DISCONNECTED - Anonymous, Session: {}", sessionId);
        }
    }

    @EventListener
    public void handleSessionSubscribe(SessionSubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        Principal user = headerAccessor.getUser();
        String destination = headerAccessor.getDestination();
        String sessionId = headerAccessor.getSessionId();
        
        if (user != null) {
            log.debug("WebSocket SUBSCRIBE - User: {}, Destination: {}, Session: {}", 
                user.getName(), destination, sessionId);
        } else {
            log.debug("WebSocket SUBSCRIBE - Anonymous, Destination: {}, Session: {}", 
                destination, sessionId);
        }
    }

    @EventListener
    public void handleSessionUnsubscribe(SessionUnsubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        
        log.debug("WebSocket UNSUBSCRIBE - Session: {}", sessionId);
    }
}
