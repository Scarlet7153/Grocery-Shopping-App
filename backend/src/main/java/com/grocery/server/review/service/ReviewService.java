package com.grocery.server.review.service;

import com.grocery.server.order.entity.Order;
import com.grocery.server.order.repository.OrderRepository;
import com.grocery.server.review.dto.request.CreateReviewRequest;
import com.grocery.server.review.dto.request.UpdateReviewRequest;
import com.grocery.server.review.dto.response.ReviewResponse;
import com.grocery.server.review.dto.response.StoreRatingResponse;
import com.grocery.server.review.entity.Review;
import com.grocery.server.review.repository.ReviewRepository;
import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import com.grocery.server.notification.service.NotificationService;
import com.grocery.server.notification.document.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

/**
 * Service: ReviewService
 * Mô tả: Xử lý business logic cho Review Module
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final StoreRepository storeRepository;
    private final NotificationService notificationService;

    /**
     * Tạo đánh giá mới
     * Chỉ customer có thể đánh giá sau khi đơn hàng đã giao thành công
     * @param request Thông tin đánh giá
     * @param reviewerId ID người đánh giá
     * @return ReviewResponse
     */
    @Transactional
    public ReviewResponse createReview(CreateReviewRequest request, Long reviewerId) {
        log.info("Creating review for order: {} by user: {}", request.getOrderId(), reviewerId);

        // 1. Kiểm tra user tồn tại
        User reviewer = userRepository.findById(reviewerId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + reviewerId));

        // 2. Kiểm tra đơn hàng tồn tại
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + request.getOrderId()));

        // 3. Kiểm tra đơn hàng thuộc về customer đang đánh giá
        if (!order.getCustomer().getId().equals(reviewerId)) {
            throw new UnauthorizedException("You can only review your own orders");
        }

        // 4. Kiểm tra đơn hàng đã giao thành công
        if (order.getStatus() != Order.OrderStatus.DELIVERED) {
            throw new BadRequestException("You can only review delivered orders");
        }

        // 5. Kiểm tra đơn hàng chưa được đánh giá
        if (reviewRepository.existsByOrderId(request.getOrderId())) {
            throw new BadRequestException("This order has already been reviewed");
        }

        // 6. Tạo review mới
        Review review = Review.builder()
                .order(order)
                .reviewer(reviewer)
                .store(order.getStore())
                .rating(request.getRating())
                .comment(request.getComment())
                .build();

        Review savedReview = reviewRepository.save(review);
        log.info("Review created successfully with id: {}", savedReview.getId());

        // Gửi thông báo đến chủ cửa hàng
        if (order.getStore().getOwner() != null) {
            notificationService.createAndSend(
                order.getStore().getOwner().getId(),
                Notification.NEW_REVIEW,
                "Đánh giá mới từ " + reviewer.getFullName(),
                "Khách hàng đã đánh giá " + request.getRating() + " sao cho đơn hàng #" + order.getId(),
                savedReview.getId(),
                "REVIEW"
            );
        }

        return mapToResponse(savedReview);
    }

    /**
     * Cập nhật đánh giá
     * Chỉ người tạo đánh giá mới có quyền cập nhật
     * @param reviewId ID đánh giá
     * @param request Thông tin cập nhật
     * @param userId ID người dùng
     * @return ReviewResponse
     */
    @Transactional
    public ReviewResponse updateReview(Long reviewId, UpdateReviewRequest request, Long userId) {
        log.info("Updating review: {} by user: {}", reviewId, userId);

        // 1. Kiểm tra review tồn tại
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with id: " + reviewId));

        // 2. Kiểm tra quyền sở hữu
        if (!review.getReviewer().getId().equals(userId)) {
            throw new UnauthorizedException("You can only update your own reviews");
        }

        // 3. Cập nhật thông tin
        review.setRating(request.getRating());
        review.setComment(request.getComment());

        Review updatedReview = reviewRepository.save(review);
        log.info("Review updated successfully: {}", reviewId);

        return mapToResponse(updatedReview);
    }

    /**
     * Xóa đánh giá
     * Chỉ người tạo đánh giá hoặc admin mới có quyền xóa
     * @param reviewId ID đánh giá
     * @param userId ID người dùng
     */
    @Transactional
    public void deleteReview(Long reviewId, Long userId) {
        log.info("Deleting review: {} by user: {}", reviewId, userId);

        // 1. Kiểm tra review tồn tại
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with id: " + reviewId));

        // 2. Kiểm tra quyền
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        boolean isOwner = review.getReviewer().getId().equals(userId);
        boolean isAdmin = user.getRole() == User.UserRole.ADMIN;

        if (!isOwner && !isAdmin) {
            throw new UnauthorizedException("You can only delete your own reviews");
        }

        // 3. Xóa review
        reviewRepository.delete(review);
        log.info("Review deleted successfully: {}", reviewId);
    }

    /**
     * Phản hồi đánh giá từ cửa hàng
     * Chỉ chủ cửa hàng mới có quyền phản hồi
     * @param reviewId ID đánh giá
     * @param request Thông tin phản hồi
     * @param storeId ID cửa hàng
     * @return ReviewResponse
     */
    @Transactional
    public ReviewResponse replyToReview(Long reviewId, String reply, Long storeId) {
        log.info("Replying to review: {} by store: {}", reviewId, storeId);

        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with id: " + reviewId));

        if (!review.getStore().getId().equals(storeId)) {
            throw new UnauthorizedException("You can only reply to reviews of your own store");
        }

        review.setStoreReply(reply);
        review.setStoreReplyAt(LocalDateTime.now());

        Review updatedReview = reviewRepository.save(review);
        log.info("Review replied successfully: {}", reviewId);

        // Gửi thông báo đến khách hàng
        notificationService.createAndSend(
            review.getReviewer().getId(),
            Notification.REVIEW_REPLIED,
            "Phản hồi từ cửa hàng",
            "Cửa hàng " + review.getStore().getStoreName() + " đã phản hồi đánh giá của bạn",
            updatedReview.getId(),
            "REVIEW"
        );

        return mapToResponse(updatedReview);
    }

    /**
     * Lấy thông tin đánh giá theo ID
     * @param reviewId ID đánh giá
     * @return ReviewResponse
     */
    @Transactional(readOnly = true)
    public ReviewResponse getReviewById(Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with id: " + reviewId));

        return mapToResponse(review);
    }

    /**
     * Lấy tất cả đánh giá của một cửa hàng (phân trang)
     * @param storeId ID cửa hàng
     * @param page Số trang (0-based)
     * @param size Kích thước trang
     * @return Page<ReviewResponse>
     */
    @Transactional(readOnly = true)
    public Page<ReviewResponse> getReviewsByStore(Long storeId, int page, int size) {
        if (!storeRepository.existsById(storeId)) {
            throw new ResourceNotFoundException("Store not found with id: " + storeId);
        }

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Review> reviews = reviewRepository.findByStoreId(storeId, pageRequest);
        return reviews.map(this::mapToResponse);
    }

    /**
     * Lấy tất cả đánh giá của một cửa hàng (không phân trang - deprecated)
     * @param storeId ID cửa hàng
     * @return List<ReviewResponse>
     */
    @Transactional(readOnly = true)
    public List<ReviewResponse> getReviewsByStore(Long storeId) {
        if (!storeRepository.existsById(storeId)) {
            throw new ResourceNotFoundException("Store not found with id: " + storeId);
        }

        List<Review> reviews = reviewRepository.findByStoreId(storeId);
        return reviews.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy tất cả đánh giá của người dùng hiện tại
     * @param userId ID người dùng
     * @return List<ReviewResponse>
     */
    @Transactional(readOnly = true)
    public List<ReviewResponse> getMyReviews(Long userId) {
        List<Review> reviews = reviewRepository.findByReviewerId(userId);
        return reviews.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy đánh giá theo order ID
     * Trả về review nếu có, hoặc null nếu đơn chưa được đánh giá
     * @param orderId ID đơn hàng
     * @return ReviewResponse hoặc null
     */
    @Transactional(readOnly = true)
    public ReviewResponse getReviewByOrderId(Long orderId) {
        return reviewRepository.findByOrderId(orderId)
                .map(this::mapToResponse)
                .orElse(null);
    }

    /**
     * Lấy điểm đánh giá trung bình của cửa hàng
     * @param storeId ID cửa hàng
     * @return StoreRatingResponse
     */
    @Transactional(readOnly = true)
    public StoreRatingResponse getStoreRating(Long storeId) {
        // Kiểm tra store tồn tại
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store not found with id: " + storeId));

        // Tính điểm trung bình
        Double averageRating = reviewRepository.calculateAverageRating(storeId);
        long totalReviews = reviewRepository.countByStoreId(storeId);

        return StoreRatingResponse.builder()
                .storeId(storeId)
                .storeName(store.getStoreName())
                .averageRating(averageRating != null ? Math.round(averageRating * 10.0) / 10.0 : 0.0)
                .totalReviews(totalReviews)
                .build();
    }

    /**
     * Map Review entity sang ReviewResponse DTO
     * @param review Review entity
     * @return ReviewResponse
     */
    private ReviewResponse mapToResponse(Review review) {
        return ReviewResponse.builder()
                .id(review.getId())
                .orderId(review.getOrder().getId())
                .reviewerId(review.getReviewer().getId())
                .reviewerName(review.getReviewer().getFullName())
                .storeId(review.getStore().getId())
                .storeName(review.getStore().getStoreName())
                .rating(review.getRating())
                .comment(review.getComment())
                .storeReply(review.getStoreReply())
                .storeReplyAt(review.getStoreReplyAt())
                .createdAt(review.getCreatedAt())
                .build();
    }
}
