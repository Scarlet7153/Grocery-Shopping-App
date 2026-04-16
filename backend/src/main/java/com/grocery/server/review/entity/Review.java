package com.grocery.server.review.entity;

import com.grocery.server.order.entity.Order;
import com.grocery.server.store.entity.Store;
import com.grocery.server.user.entity.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Entity: reviews
 * Mô tả: Bảng đánh giá
 */
@Entity
@Table(name = "reviews")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Đánh giá dựa trên đơn hàng nào
     */
    @OneToOne
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    /**
     * Khách hàng viết đánh giá
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewer_id", nullable = false)
    private User reviewer;

    /**
     * Cửa hàng được đánh giá
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_id", nullable = false)
    private Store store;

    /**
     * Điểm số đánh giá (1-5 sao)
     */
    @Column(nullable = false)
    private Integer rating;

    /**
     * Nội dung bình luận, lời khen chê
     */
    @Column(columnDefinition = "TEXT")
    private String comment;

    /**
     * Phản hồi từ cửa hàng
     */
    @Column(name = "store_reply", columnDefinition = "TEXT")
    private String storeReply;

    /**
     * Thời gian phản hồi từ cửa hàng
     */
    @Column(name = "store_reply_at")
    private LocalDateTime storeReplyAt;

    /**
     * Thời gian viết đánh giá
     */
    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // ========== VALIDATION ==========

    /**
     * Kiểm tra rating hợp lệ (1-5)
     */
    @PrePersist
    @PreUpdate
    private void validateRating() {
        if (rating == null || rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Rating must be between 1 and 5");
        }
    }
}
