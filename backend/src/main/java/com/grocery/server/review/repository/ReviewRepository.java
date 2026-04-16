package com.grocery.server.review.repository;

import com.grocery.server.review.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository: ReviewRepository
 * Mô tả: Interface truy vấn dữ liệu từ bảng reviews
 */
@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {

    /**
     * Tìm đánh giá theo ID cửa hàng
     * @param storeId ID cửa hàng
     * @return Danh sách đánh giá theo cửa hàng
     */
    List<Review> findByStoreId(Long storeId);

    Page<Review> findByStoreId(Long storeId, Pageable pageable);

    /**
     * Tìm đánh giá theo ID người đánh giá
     * @param reviewerId ID người đánh giá
     * @return Danh sách đánh giá của người dùng
     */
    List<Review> findByReviewerId(Long reviewerId);

    /**
     * Tìm đánh giá theo ID đơn hàng
     * @param orderId ID đơn hàng
     * @return Đánh giá của đơn hàng (nếu có)
     */
    Optional<Review> findByOrderId(Long orderId);

    /**
     * Kiểm tra đơn hàng đã có đánh giá chưa
     * @param orderId ID đơn hàng
     * @return true nếu đã có đánh giá
     */
    boolean existsByOrderId(Long orderId);

    /**
     * Tính điểm trung bình của cửa hàng
     * @param storeId ID cửa hàng
     * @return Điểm trung bình (null nếu chưa có đánh giá)
     */
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.store.id = :storeId")
    Double calculateAverageRating(@Param("storeId") Long storeId);

    /**
     * Đếm số lượng đánh giá của cửa hàng
     * @param storeId ID cửa hàng
     * @return Số lượng đánh giá
     */
    long countByStoreId(Long storeId);
}
