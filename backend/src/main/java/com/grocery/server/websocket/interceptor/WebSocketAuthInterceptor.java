package com.grocery.server.websocket.interceptor;

import com.grocery.server.auth.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Interceptor: WebSocketAuthInterceptor
 * Mục đích: Xác thực JWT token khi client kết nối WebSocket
 * Phase: 2 - WebSocket Security
 * 
 * Xử lý:
 * - CONNECT: Validate JWT từ header "Authorization"
 * - SUBSCRIBE/MESSAGE: Kiểm tra authentication
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private final JwtTokenProvider jwtTokenProvider;
    private final UserDetailsService userDetailsService;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        
        if (accessor == null) {
            return message;
        }

        // Xử lý CONNECT command - Validate JWT token
        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            log.debug("WebSocket CONNECT request - validating JWT token");
            
            List<String> authorization = accessor.getNativeHeader("Authorization");
            
            if (authorization != null && !authorization.isEmpty()) {
                String token = authorization.get(0);
                
                // Remove "Bearer " prefix nếu có
                if (token.startsWith("Bearer ")) {
                    token = token.substring(7);
                }
                
                try {
                    // Validate token
                    if (jwtTokenProvider.validateToken(token)) {
                        String phoneNumber = jwtTokenProvider.getPhoneNumberFromToken(token);
                        UserDetails userDetails = userDetailsService.loadUserByUsername(phoneNumber);
                        
                        Authentication authentication = new UsernamePasswordAuthenticationToken(
                                userDetails, null, userDetails.getAuthorities());
                        
                        // Set authentication vào accessor
                        accessor.setUser(authentication);
                        SecurityContextHolder.getContext().setAuthentication(authentication);
                        
                        log.debug("WebSocket authentication successful for user: {}", phoneNumber);
                    } else {
                        log.warn("Invalid JWT token in WebSocket connection");
                    }
                } catch (Exception e) {
                    log.error("Error validating JWT token: {}", e.getMessage());
                }
            } else {
                log.warn("No Authorization header in WebSocket CONNECT");
            }
        }
        
        // Xử lý SUBSCRIBE/MESSAGE - Kiểm tra authentication
        if (StompCommand.SUBSCRIBE.equals(accessor.getCommand()) || 
            StompCommand.SEND.equals(accessor.getCommand())) {
            
            Authentication authentication = (Authentication) accessor.getUser();
            
            if (authentication == null || !authentication.isAuthenticated()) {
                log.warn("Unauthenticated WebSocket {} request", accessor.getCommand());
                // Có thể throw exception để reject message
            } else {
                log.debug("Authenticated WebSocket {} from user: {}", 
                    accessor.getCommand(), authentication.getName());
            }
        }

        return message;
    }
}
