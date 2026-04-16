package com.grocery.server.user.service;

import com.grocery.server.messaging.dto.UserProfileUpdatedEvent;
import com.grocery.server.messaging.publisher.RedisMessagePublisher;
import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.user.dto.request.ChangePasswordRequest;
import com.grocery.server.user.dto.request.UpdateProfileRequest;
import com.grocery.server.user.dto.response.UserListResponse;
import com.grocery.server.user.dto.response.UserProfileResponse;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service: UserService
 * Mục đích: Xử lý business logic cho User module
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final RedisMessagePublisher messagePublisher;

    /**
     * Lấy thông tin user hiện tại (từ JWT token)
     */
    public UserProfileResponse getCurrentUserProfile() {
        User user = getCurrentUser();
        log.info("Get profile for user: {}", user.getPhoneNumber());
        return UserProfileResponse.fromEntity(user);
    }

    /**
     * Lấy thông tin user theo ID
     */
    public UserProfileResponse getUserById(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        
        log.info("Get user by ID: {}", userId);
        return UserProfileResponse.fromEntity(user);
    }

    /**
     * Cập nhật thông tin profile
     */
    @Transactional
    public UserProfileResponse updateProfile(UpdateProfileRequest request) {
        User user = getCurrentUser();
        
        user.setFullName(request.getFullName());
        user.setAddress(request.getAddress());
        
        if (request.getAvatarUrl() != null && !request.getAvatarUrl().isEmpty()) {
            user.setAvatarUrl(request.getAvatarUrl());
        }
        
        User updatedUser = userRepository.save(user);
        publishUserProfileUpdatedEvent(updatedUser);
        log.info("Updated profile for user: {}", user.getPhoneNumber());
        
        return UserProfileResponse.fromEntity(updatedUser);
    }

    /**
     * Đổi mật khẩu
     */
    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        User user = getCurrentUser();
        
        // Kiểm tra mật khẩu cũ
        if (!passwordEncoder.matches(request.getOldPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Mật khẩu cũ không đúng");
        }

        // Không cho phép dùng lại mật khẩu hiện tại
        if (passwordEncoder.matches(request.getNewPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Mật khẩu mới không được trùng mật khẩu cũ");
        }
        
        // Kiểm tra mật khẩu mới khớp với confirm password
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Mật khẩu mới và xác nhận mật khẩu không khớp");
        }
        
        // Cập nhật mật khẩu mới
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        
        log.info("Changed password for user: {}", user.getPhoneNumber());
    }

    /**
     * Lấy danh sách tất cả users (Admin only)
     */
    public List<UserListResponse> getAllUsers() {
        List<User> users = userRepository.findAll();
        log.info("Get all users, total: {}", users.size());
        
        return users.stream()
                .map(UserListResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Lấy danh sách users theo role (Admin only)
     */
    public List<UserListResponse> getUsersByRole(User.UserRole role) {
        List<User> users = userRepository.findByRole(role);
        log.info("Get users by role: {}, total: {}", role, users.size());
        
        return users.stream()
                .map(UserListResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Cấm/Mở khóa user (Admin only)
     */
    @Transactional
    public UserProfileResponse toggleUserStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        
        // Toggle status
        if (user.getStatus() == User.UserStatus.ACTIVE) {
            user.setStatus(User.UserStatus.BANNED);
            log.info("Banned user: {}", user.getPhoneNumber());
        } else {
            user.setStatus(User.UserStatus.ACTIVE);
            log.info("Activated user: {}", user.getPhoneNumber());
        }
        
        User updatedUser = userRepository.save(user);
        return UserProfileResponse.fromEntity(updatedUser);
    }

    /**
     * Xóa user (Admin only)
     */
    @Transactional
    public void deleteUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        
        // Không cho phép xóa admin
        if (user.getRole() == User.UserRole.ADMIN) {
            throw new BadRequestException("Không thể xóa tài khoản Admin");
        }
        
        userRepository.delete(user);
        log.info("Deleted user: {}", user.getPhoneNumber());
    }
    @Transactional
    public List<UserListResponse> getUsersByStatus(User.UserStatus status) {
        List<User> users = userRepository.findByStatus(status);
        log.info("Get users by status: {}, total: {}", status, users.size());

        return users.stream()
                .map(UserListResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Lấy ID của user hiện tại
     */
    public Long getCurrentUserId() {
        User user = getCurrentUser();
        return user.getId();
    }

    /**
     * Helper: Lấy current user từ SecurityContext
     */
    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String phoneNumber = authentication.getName();
        
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UnauthorizedException("User không tồn tại hoặc đã bị xóa"));
    }

    private void publishUserProfileUpdatedEvent(User user) {
        UserProfileUpdatedEvent event = UserProfileUpdatedEvent.builder()
                .eventType("USER_PROFILE_UPDATED")
                .timestamp(System.currentTimeMillis())
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .avatarUrl(user.getAvatarUrl())
                .address(user.getAddress())
                .updatedAt(user.getUpdatedAt() != null ? user.getUpdatedAt() : LocalDateTime.now())
                .build();

        messagePublisher.publish("user:profile:" + user.getId(), event);
    }


}
