package com.grocery.server.review.controller;

import com.grocery.server.review.dto.request.CreateReviewRequest;
import com.grocery.server.review.dto.request.UpdateReviewRequest;
import com.grocery.server.review.dto.response.ReviewResponse;
import com.grocery.server.review.dto.response.StoreRatingResponse;
import com.grocery.server.review.service.ReviewService;
import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller: ReviewController
 * Endpoint: /api/reviews
 * Mô tả: Quản lý đánh giá (Review Management)
 */
@RestController
@RequestMapping("/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;
    private final UserRepository userRepository;

    /**
     * Tạo đánh giá mới
     * POST /api/reviews
     * Role: CUSTOMER (chỉ sau khi order delivered)
     */
    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<ReviewResponse>> createReview(
            @Valid @RequestBody CreateReviewRequest request,
            Authentication authentication) {

        Long reviewerId = getUserIdFromAuthentication(authentication);
        ReviewResponse response = reviewService.createReview(request, reviewerId);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo đánh giá thành công", response));
    }

    /**
     * Cập nhật đánh giá
     * PUT /api/reviews/{id}
     * Role: CUSTOMER (chỉ người tạo)
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<ReviewResponse>> updateReview(
            @PathVariable Long id,
            @Valid @RequestBody UpdateReviewRequest request,
            Authentication authentication) {

        Long userId = getUserIdFromAuthentication(authentication);
        ReviewResponse response = reviewService.updateReview(id, request, userId);

        return ResponseEntity.ok(ApiResponse.success("Cập nhật đánh giá thành công", response));
    }

    /**
     * Xóa đánh giá
     * DELETE /api/reviews/{id}
     * Role: CUSTOMER (chỉ người tạo) hoặc ADMIN
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('CUSTOMER', 'ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteReview(
            @PathVariable Long id,
            Authentication authentication) {

        Long userId = getUserIdFromAuthentication(authentication);
        reviewService.deleteReview(id, userId);

        return ResponseEntity.ok(ApiResponse.success("Xóa đánh giá thành công", null));
    }

    /**
     * Lấy thông tin đánh giá theo ID
     * GET /api/reviews/{id}
     * Role: Public
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ReviewResponse>> getReviewById(@PathVariable Long id) {
        ReviewResponse response = reviewService.getReviewById(id);
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin đánh giá thành công", response));
    }

    /**
     * Lấy tất cả đánh giá của một cửa hàng
     * GET /api/reviews/store/{storeId}
     * Role: Public
     */
    @GetMapping("/store/{storeId}")
    public ResponseEntity<ApiResponse<List<ReviewResponse>>> getReviewsByStore(@PathVariable Long storeId) {
        List<ReviewResponse> reviews = reviewService.getReviewsByStore(storeId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đánh giá thành công", reviews));
    }

    /**
     * Lấy tất cả đánh giá của người dùng hiện tại
     * GET /api/reviews/my-reviews
     * Role: CUSTOMER
     */
    @GetMapping("/my-reviews")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<List<ReviewResponse>>> getMyReviews(Authentication authentication) {
        Long userId = getUserIdFromAuthentication(authentication);
        List<ReviewResponse> reviews = reviewService.getMyReviews(userId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đánh giá thành công", reviews));
    }

    /**
     * Lấy điểm đánh giá trung bình của cửa hàng
     * GET /api/reviews/store/{storeId}/rating
     * Role: Public
     */
    @GetMapping("/store/{storeId}/rating")
    public ResponseEntity<ApiResponse<StoreRatingResponse>> getStoreRating(@PathVariable Long storeId) {
        StoreRatingResponse response = reviewService.getStoreRating(storeId);
        return ResponseEntity.ok(ApiResponse.success("Lấy điểm đánh giá cửa hàng thành công", response));
    }

    /**
     * Helper method: Lấy User ID từ Authentication
     */
    private Long getUserIdFromAuthentication(Authentication authentication) {
        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("User not found"));
        return user.getId();
    }
}
