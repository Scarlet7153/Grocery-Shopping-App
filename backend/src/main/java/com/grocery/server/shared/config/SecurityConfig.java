package com.grocery.server.shared.config;

import com.grocery.server.auth.security.CustomUserDetailsService;
import com.grocery.server.auth.security.JwtAuthenticationFilter;
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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final CustomUserDetailsService userDetailsService;
    private final JwtAuthenticationFilter jwtAuthFilter;

    public SecurityConfig(CustomUserDetailsService userDetailsService,
                          JwtAuthenticationFilter jwtAuthFilter) {
        this.userDetailsService = userDetailsService;
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/auth/**", "/public/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/stores", "/stores/open", "/stores/search").permitAll()
                .requestMatchers(HttpMethod.GET, "/stores/*", "/categories/**", "/products/**").permitAll()

                .requestMatchers(HttpMethod.GET, "/stores/my-store").hasRole("STORE")
                .requestMatchers(HttpMethod.PUT, "/stores/**").hasRole("STORE")
                .requestMatchers(HttpMethod.PATCH, "/stores/**").hasRole("STORE")
                .requestMatchers(HttpMethod.DELETE, "/stores/**").hasAnyRole("STORE", "ADMIN")

                .requestMatchers(HttpMethod.POST, "/products").hasRole("STORE")
                .requestMatchers(HttpMethod.PUT, "/products/**").hasRole("STORE")
                .requestMatchers(HttpMethod.PATCH, "/products/**").hasRole("STORE")
                .requestMatchers(HttpMethod.DELETE, "/products/**").hasRole("STORE")

                .requestMatchers(HttpMethod.POST, "/categories").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/categories/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/categories/**").hasRole("ADMIN")

                .requestMatchers(HttpMethod.POST, "/orders").hasRole("CUSTOMER")
                .requestMatchers(HttpMethod.GET, "/orders/my-orders").hasRole("CUSTOMER")
                .requestMatchers(HttpMethod.GET, "/orders/my-store-orders").hasRole("STORE")
                .requestMatchers(HttpMethod.GET, "/orders/my-deliveries").hasRole("SHIPPER")
                .requestMatchers(HttpMethod.GET, "/orders/available").hasRole("SHIPPER")
                .requestMatchers(HttpMethod.POST, "/orders/*/assign-shipper").hasRole("SHIPPER")
                .requestMatchers(HttpMethod.GET, "/orders/*").authenticated()
                .requestMatchers(HttpMethod.PATCH, "/orders/*/status").authenticated()

                .requestMatchers("/users/profile/**").authenticated()
                .requestMatchers("/users/change-password").authenticated()
                .requestMatchers("/users/**").hasRole("ADMIN")

                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/customer/**").hasRole("CUSTOMER")
                .requestMatchers("/shipper/**").hasRole("SHIPPER")

                .requestMatchers("/reviews").hasRole("CUSTOMER")
                .requestMatchers("/reviews/**").permitAll()

                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("http://localhost:*", "http://127.0.0.1:*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }
}