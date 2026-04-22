package com.grocery.server.user.controller;

import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.user.dto.request.ChangePasswordRequest;
import com.grocery.server.user.dto.request.UpdateProfileRequest;
import com.grocery.server.user.dto.response.StoreApprovalResponse;
import com.grocery.server.user.dto.response.UserListResponse;
import com.grocery.server.user.dto.response.UserProfileResponse;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller: UserController
 * Mục đích: REST API cho User module
 * 
 * Base URL: /api/users
 */
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Slf4j
public class UserController {

    private final UserService userService;

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getCurrentUserProfile() {
        log.info("GET /api/users/profile - Get current user profile");
        
        UserProfileResponse profile = userService.getCurrentUserProfile();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin profile thành công", profile)
        );
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request) {
        
        log.info("PUT /api/users/profile - Update profile");
        
        UserProfileResponse profile = userService.updateProfile(request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật profile thành công", profile)
        );
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request) {
        
        log.info("POST /api/users/change-password - Change password");
        
        userService.changePassword(request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Đổi mật khẩu thành công", null)
        );
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<UserListResponse>>> getAllUsers() {
        log.info("GET /api/users - Get all users (Admin)");
        
        List<UserListResponse> users = userService.getAllUsers();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách users thành công", users)
        );
    }

    @GetMapping("/role/{role}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<UserListResponse>>> getUsersByRole(
            @PathVariable String role) {
        
        log.info("GET /api/users/role/{} - Get users by role (Admin)", role);
        
        User.UserRole userRole = User.UserRole.valueOf(role.toUpperCase());
        List<UserListResponse> users = userService.getUsersByRole(userRole);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách users theo role thành công", users)
        );
    }

    @GetMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getUserById(
            @PathVariable Long userId) {
        
        log.info("GET /api/users/{} - Get user by ID (Admin)", userId);
        
        UserProfileResponse user = userService.getUserById(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin user thành công", user)
        );
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<UserListResponse>>> getUsersByStatus(
            @PathVariable String status) {

        log.info("GET /api/users/role/{} - Get users by status (Admin)", status);

        User.UserStatus userStatus = User.UserStatus.valueOf(status.toUpperCase());
        List<UserListResponse> users = userService.getUsersByStatus(userStatus);

        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách users theo status thành công", users)
        );
    }

    @GetMapping("/stores/pending")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<StoreApprovalResponse>>> getPendingStores() {

        log.info("GET /api/users/stores/pending - Get pending stores (Admin)");

        List<StoreApprovalResponse> stores = userService.getPendingStores();

        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách cửa hàng chờ duyệt thành công", stores)
        );
    }

    @PatchMapping("/{userId}/toggle-status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserProfileResponse>> toggleUserStatus(
            @PathVariable Long userId) {
        
        log.info("PATCH /api/users/{}/toggle-status - Toggle user status (Admin)", userId);
        
        UserProfileResponse user = userService.toggleUserStatus(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật trạng thái user thành công", user)
        );
    }

    @PatchMapping("/{userId}/approve-store")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserProfileResponse>> approveStore(
            @PathVariable Long userId) {
        
        log.info("PATCH /api/users/{}/approve-store - Approve store (Admin)", userId);
        
        UserProfileResponse user = userService.approveStore(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Duyệt cửa hàng thành công", user)
        );
    }

    @PatchMapping("/{userId}/reject-store")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserProfileResponse>> rejectStore(
            @PathVariable Long userId) {
        
        log.info("PATCH /api/users/{}/reject-store - Reject store (Admin)", userId);
        
        UserProfileResponse user = userService.rejectStore(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Từ chối cửa hàng thành công", user)
        );
    }

    @DeleteMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteUser(
            @PathVariable Long userId) {
        
        log.info("DELETE /api/users/{} - Delete user (Admin)", userId);
        
        userService.deleteUser(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa user thành công", null)
        );
    }
}
