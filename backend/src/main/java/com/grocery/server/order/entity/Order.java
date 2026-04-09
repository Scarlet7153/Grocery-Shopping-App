package com.grocery.server.order.entity;

import com.grocery.server.payment.entity.Payment;
import com.grocery.server.review.entity.Review;
import com.grocery.server.store.entity.Store;
import com.grocery.server.user.entity.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Entity: orders
 * Mô tả: Bảng đơn hàng
 */
@Entity
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Khách hàng đặt hàng (User có role = CUSTOMER)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private User customer;

    /**
     * Cửa hàng bán hàng
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_id", nullable = false)
    private Store store;

    /**
     * Tài xế giao hàng (User có role = SHIPPER)
     * NULL khi mới đặt, ai nhận đơn thì điền ID vào đây
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shipper_id")
    private User shipper;

    /**
     * Tình trạng đơn hàng:
     * - PENDING: Chờ xác nhận
     * - CONFIRMED: Đã xác nhận
     * - PICKING_UP: Đang lấy hàng
     * - DELIVERING: Đang giao hàng
     * - DELIVERED: Đã giao thành công
     * - CANCELLED: Đã hủy
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private OrderStatus status = OrderStatus.PENDING;

    /**
     * Tổng tiền hàng hóa (VNĐ)
     */
    @Column(name = "total_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmount;

    /**
     * Tiền phí vận chuyển (VNĐ)
     */
    @Column(name = "shipping_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal shippingFee;

    /**
     * Địa chỉ giao hàng cụ thể
     */
    @Column(name = "delivery_address", nullable = false)
    private String deliveryAddress;

    /**
     * Ảnh bằng chứng giao hàng (POD - Proof of Delivery)
     * Tài xế chụp khi giao hàng tới nơi
     */
    @Column(name = "pod_image_url")
    private String podImageUrl;

    /**
     * Lý do hủy đơn (nếu đơn bị hủy)
     */
    @Column(name = "cancel_reason")
    private String cancelReason;

    /**
     * Thời gian đặt hàng
     */
    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    /**
     * Trạng thái thanh toán của đơn hàng (PENDING, SUCCESS, FAILED)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status", nullable = false)
    @Builder.Default
    private Payment.PaymentStatus paymentStatus = Payment.PaymentStatus.PENDING;
    // ========== RELATIONSHIPS ==========

    /**
     * Chi tiết các sản phẩm trong đơn hàng
     */
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> orderItems;

    /**
     * Lịch sử thanh toán của đơn hàng
     */
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Payment> payments;

    /**
     * Đánh giá của đơn hàng này
     */
    @OneToOne(mappedBy = "order", cascade = CascadeType.ALL)
    private Review review;

    // ========== ENUMS ==========

    public enum OrderStatus {
        PENDING,        // Chờ xác nhận
        CONFIRMED,      // Đã xác nhận
        PICKING_UP,     // Đang lấy hàng
        DELIVERING,     // Đang giao
        DELIVERED,      // Hoàn thành
        CANCELLED       // Đã hủy
    }
}
