package com.grocery.server.shared.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

/**
 * Configuration: CorsConfig
 * Mục đích: Cấu hình CORS (Cross-Origin Resource Sharing) để cho phép Flutter Web gọi API
 */
@Configuration
public class CorsConfig {
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // Cho phép các origin này gọi API - sử dụng patterns để match localhost với bất kỳ port nào
        configuration.setAllowedOriginPatterns(Arrays.asList(
            "http://localhost:*",      // Flutter Web (mọi port)
            "http://127.0.0.1:*",      // Local loopback (mọi port)
            "http://localhost:[0-9]+", // Regex pattern match
            "http://127.0.0.1:[0-9]+"
        ));
        
        // Cho phép HTTP methods
        configuration.setAllowedMethods(Arrays.asList(
            "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"
        ));
        
        // Cho phép tất cả headers
        configuration.setAllowedHeaders(Arrays.asList("*"));
        
        // Cho phép credentials (cookies, JWT tokens)
        configuration.setAllowCredentials(true);
        
        // Cache preflight response cho 1 giờ (3600 giây)
        configuration.setMaxAge(3600L);
        
        // Expose headers (nếu cần)
        configuration.setExposedHeaders(Arrays.asList(
            "Authorization", "X-Total-Count", "X-Page-Number", "X-Page-Size"
        ));
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
