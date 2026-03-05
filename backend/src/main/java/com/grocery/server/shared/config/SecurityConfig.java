package com.grocery.server.shared.config;

import com.grocery.server.auth.security.CustomUserDetailsService;
import com.grocery.server.auth.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Configuration: SecurityConfig
 * Mục đích: Cấu hình Spring Security
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {
    
    private final CustomUserDetailsService userDetailsService;
    private final JwtAuthenticationFilter jwtAuthFilter;
    
    /**
     * Cấu hình SecurityFilterChain
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Tắt CSRF vì dùng JWT (stateless)
            .csrf(AbstractHttpConfigurer::disable)
            
            // Cấu hình authorization
            .authorizeHttpRequests(auth -> auth
                // ========== PUBLIC ENDPOINTS (Không cần authentication) ==========
                
                // Auth endpoints
                .requestMatchers("/auth/**").permitAll()
                .requestMatchers("/public/**").permitAll()
                
                // Store public endpoints (GET only - xem danh sách, tìm kiếm, chi tiết)
                .requestMatchers(HttpMethod.GET, "/stores").permitAll()
                .requestMatchers(HttpMethod.GET, "/stores/open").permitAll()
                .requestMatchers(HttpMethod.GET, "/stores/search").permitAll()
                .requestMatchers(HttpMethod.GET, "/stores/*").permitAll()
                
                // Category & Product public endpoints (GET only)
                .requestMatchers(HttpMethod.GET, "/categories/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/products/**").permitAll()
                
                // ========== PROTECTED ENDPOINTS (Cần authentication + role) ==========
                
                // Store management endpoints (STORE role only)
                .requestMatchers(HttpMethod.GET, "/stores/my-store").hasRole("STORE")
                .requestMatchers(HttpMethod.PUT, "/stores/**").hasRole("STORE")
                .requestMatchers(HttpMethod.PATCH, "/stores/**").hasRole("STORE")
                .requestMatchers(HttpMethod.DELETE, "/stores/**").hasAnyRole("STORE", "ADMIN")
                
                // Product management endpoints (STORE role only)
                .requestMatchers(HttpMethod.POST, "/products").hasRole("STORE")
                .requestMatchers(HttpMethod.PUT, "/products/**").hasRole("STORE")
                .requestMatchers(HttpMethod.PATCH, "/products/**").hasRole("STORE")
                .requestMatchers(HttpMethod.DELETE, "/products/**").hasRole("STORE")
                
                // Category management endpoints (ADMIN only)
                .requestMatchers(HttpMethod.POST, "/categories").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/categories/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/categories/**").hasRole("ADMIN")
                
                // Order endpoints (role-based access defined in controller with @PreAuthorize)
                .requestMatchers(HttpMethod.POST, "/orders").hasRole("CUSTOMER")
                .requestMatchers(HttpMethod.GET, "/orders/my-orders").hasRole("CUSTOMER")
                .requestMatchers(HttpMethod.GET, "/orders/my-store-orders").hasRole("STORE")
                .requestMatchers(HttpMethod.GET, "/orders/my-deliveries").hasRole("SHIPPER")
                .requestMatchers(HttpMethod.GET, "/orders/available").hasRole("SHIPPER")
                .requestMatchers(HttpMethod.POST, "/orders/*/assign-shipper").hasRole("SHIPPER")
                .requestMatchers(HttpMethod.GET, "/orders/*").authenticated()
                .requestMatchers(HttpMethod.PATCH, "/orders/*/status").authenticated()
                
                // User endpoints (authenticated users)
                .requestMatchers("/users/profile/**").authenticated()
                .requestMatchers("/users/change-password").authenticated()
                
                // Admin endpoints
                .requestMatchers("/users/**").hasRole("ADMIN")
                .requestMatchers("/admin/**").hasRole("ADMIN")
                
                // Customer endpoints
                .requestMatchers("/customer/**").hasRole("CUSTOMER")
                
                // Shipper endpoints
                .requestMatchers("/shipper/**").hasRole("SHIPPER")

                // Review endpoints
                    .requestMatchers("/reviews").hasRole("CUSTOMER")
                    .requestMatchers("/reviews/**").permitAll()

                // Các request khác đều cần authentication
                .anyRequest().authenticated()
            )
            
            // Stateless session (không dùng session, chỉ dùng JWT)
            .sessionManagement(session -> 
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            
            // Thêm JWT filter
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    /**
     * Password encoder (BCrypt)
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    /**
     * Authentication Provider
     */
    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }
    
    /**
     * Authentication Manager
     */
    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }
}
