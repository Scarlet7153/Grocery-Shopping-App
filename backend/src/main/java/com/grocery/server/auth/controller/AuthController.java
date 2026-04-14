package com.grocery.server.auth.controller;

import com.grocery.server.auth.dto.request.LoginRequest;
import com.grocery.server.auth.dto.request.RegisterRequest;
import com.grocery.server.auth.dto.response.AuthResponse;
import com.grocery.server.auth.service.AuthService;
import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.user.dto.response.UserProfileResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller: AuthController
 * Mục đích: REST API cho Authentication & Authorization
 *
 * Base URL: /api/auth
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request) {
        
        log.info("POST /api/auth/register - Register new user: {}", request.getPhoneNumber());
        
        AuthResponse authResponse = authService.register(request);
        String message = "Đăng ký thành công";
        if ("STORE".equalsIgnoreCase(request.getRole().name())) {
            message = "Đăng ký cửa hàng thành công. Vui lòng chờ Admin phê duyệt để đăng nhập.";
        }
        
        return ResponseEntity
                .status(HttpStatus.CREATED)
            .body(ApiResponse.success(message, authResponse));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        
        log.info("POST /api/auth/login - User login: {}", request.getPhoneNumber());
        
        AuthResponse authResponse = authService.login(request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Đăng nhập thành công", authResponse)
        );
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getCurrentUser() {
        log.info("GET /api/auth/me - Get current user info");
        
        UserProfileResponse user = authService.getCurrentUser();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin user thành công", user)
        );
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        log.info("POST /api/auth/logout - User logout");
        
        authService.logout();
        
        return ResponseEntity.ok(
                ApiResponse.success("Đăng xuất thành công", null)
        );
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken() {
        log.info("POST /api/auth/refresh-token - Refresh JWT token");
        
        AuthResponse authResponse = authService.refreshToken();
        
        return ResponseEntity.ok(
                ApiResponse.success("Làm mới token thành công", authResponse)
        );
    }
}
