package com.grocery.server.auth.service;

import com.grocery.server.auth.dto.request.LoginRequest;
import com.grocery.server.auth.dto.request.RegisterRequest;
import com.grocery.server.auth.dto.response.AuthResponse;
import com.grocery.server.auth.security.JwtTokenProvider;
import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.dto.response.UserProfileResponse;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service: AuthService
 * Mục đích: Xử lý logic Authentication & Authorization
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {
    
    private final UserRepository userRepository;
    private final StoreRepository storeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final AuthenticationManager authenticationManager;
    
    /**
     * Đăng ký tài khoản mới
     * 
     * Logic:
     * 1. Kiểm tra số điện thoại đã tồn tại chưa
     * 2. Validate role (không cho tự đăng ký ADMIN)
     * 3. Nếu role = STORE → validate thông tin cửa hàng
     * 4. Tạo User và lưu vào DB
     * 5. Nếu role = STORE → tự động tạo Store liên kết
     * 6. Trả về JWT token
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // 1. Kiểm tra số điện thoại đã tồn tại chưa
        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new BadRequestException(
                "Số điện thoại " + request.getPhoneNumber() + " đã được sử dụng");
        }
        
        // 2. Validate role (không cho phép tự đăng ký làm ADMIN)
        if (request.getRole() == User.UserRole.ADMIN) {
            throw new BadRequestException("Không thể tự đăng ký tài khoản ADMIN");
        }
        
        // 3. Nếu role = STORE → validate thông tin cửa hàng bắt buộc
        if (request.getRole() == User.UserRole.STORE) {
            if (request.getStoreName() == null || request.getStoreName().trim().isEmpty()) {
                throw new BadRequestException("Tên cửa hàng không được để trống khi đăng ký với tư cách STORE");
            }
            if (request.getStoreAddress() == null || request.getStoreAddress().trim().isEmpty()) {
                throw new BadRequestException("Địa chỉ cửa hàng không được để trống khi đăng ký với tư cách STORE");
            }
        }
        
        // 4. Tạo user mới
        User user = User.builder()
                .phoneNumber(request.getPhoneNumber())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .role(request.getRole())
                .status(User.UserStatus.ACTIVE)
                .address(request.getAddress())
                .avatarUrl(request.getAvatarUrl())
                .build();
        
        // Lưu User vào database
        user = userRepository.save(user);
        
        // 5. Nếu role = STORE → tự động tạo Store
        if (request.getRole() == User.UserRole.STORE) {
            Store store = Store.builder()
                    .owner(user)
                    .storeName(request.getStoreName())
                    .address(request.getStoreAddress())
                    .isOpen(true) // Mặc định cửa hàng mở cửa
                    .build();
            
            storeRepository.save(store);
            
            log.info("User registered with STORE role: {} - Store created: {}", 
                    user.getPhoneNumber(), store.getStoreName());
        } else {
            log.info("User registered successfully: {} with role {}", 
                    user.getPhoneNumber(), user.getRole());
        }
        
        // 6. Tạo JWT token
        String token = tokenProvider.generateToken(user.getPhoneNumber());
        
        // Trả về response
        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
    
    /**
     * Đăng nhập
     */
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        // Kiểm tra user tồn tại
        User user = userRepository.findByPhoneNumber(request.getPhoneNumber())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Không tìm thấy tài khoản với số điện thoại: " + request.getPhoneNumber()));
        
        // Kiểm tra trạng thái tài khoản
        if (user.getStatus() == User.UserStatus.BANNED) {
            throw new BadRequestException("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ admin.");
        }
        
        // Authenticate user
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getPhoneNumber(),
                            request.getPassword()
                    )
            );
            
            SecurityContextHolder.getContext().setAuthentication(authentication);
            
        } catch (BadCredentialsException e) {
            log.error("Bad credentials for user: {}", request.getPhoneNumber());
            throw new BadCredentialsException("Số điện thoại hoặc mật khẩu không đúng");
        }
        
        // Tạo JWT token
        String token = tokenProvider.generateToken(request.getPhoneNumber());
        
        log.info("User logged in successfully: {} with role {}", 
                user.getPhoneNumber(), user.getRole());
        
        // Trả về response
        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
    
    /**
     * Lấy thông tin user hiện tại (từ JWT token)
     */
    @Transactional(readOnly = true)
    public UserProfileResponse getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String phoneNumber = authentication.getName();
        
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "User không tồn tại hoặc đã bị xóa"));
        
        log.info("Get current user: {}", phoneNumber);
        
        return UserProfileResponse.fromEntity(user);
    }
    
    /**
     * Đăng xuất
     * Note: JWT là stateless, client sẽ tự xóa token
     * Method này chỉ để log và có thể mở rộng thêm (blacklist token)
     */
    public void logout() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String phoneNumber = authentication.getName();
        
        log.info("User logged out: {}", phoneNumber);
        
        // Clear security context
        SecurityContextHolder.clearContext();
        

    }
    
    /**
     * Làm mới token
     */
    @Transactional(readOnly = true)
    public AuthResponse refreshToken() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String phoneNumber = authentication.getName();
        
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "User không tồn tại hoặc đã bị xóa"));
        
        // Kiểm tra trạng thái tài khoản
        if (user.getStatus() == User.UserStatus.BANNED) {
            throw new BadRequestException("Tài khoản của bạn đã bị khóa");
        }
        
        // Tạo JWT token mới
        String newToken = tokenProvider.generateToken(phoneNumber);
        
        log.info("Token refreshed for user: {}", phoneNumber);
        
        return AuthResponse.builder()
                .token(newToken)
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .role(user.getRole().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }

}
