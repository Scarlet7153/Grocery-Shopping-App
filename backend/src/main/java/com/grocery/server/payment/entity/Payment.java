package com.grocery.server.payment.entity;

import com.grocery.server.order.entity.Order;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entity: payments
 * Mô tả: Bảng lịch sử thanh toán
 */
@Entity
@Table(name = "payments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Giao dịch này thuộc về đơn hàng nào
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    /**
     * Phương thức thanh toán:
     * - COD: Tiền mặt khi nhận hàng (Cash on Delivery)
     * - MOMO: Thanh toán qua ví Momo
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", nullable = false)
    private PaymentMethod paymentMethod;

    /**
     * Số tiền của giao dịch này (VNĐ)
     */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    /**
     * Mã giao dịch trả về từ Momo
     * Lưu lại để làm bằng chứng đối soát
     * Với COD, trường này bỏ trống (NULL)
     */
    @Column(name = "transaction_code", length = 100)
    private String transactionCode;

    /**
     * Trạng thái giao dịch:
     * - PENDING: Đang chờ
     * - SUCCESS: Thành công
     * - FAILED: Thất bại/Lỗi
     * - REFUNDED: Đã hoàn tiền
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private PaymentStatus status = PaymentStatus.PENDING;

    /**
     * Thời gian tạo giao dịch
     */
    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    /**
     * Thời gian cập nhật trạng thái giao dịch
     * Lúc Momo báo tiền đã vào tài khoản
     */
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ========== ENUMS ==========

    public enum PaymentMethod {
        COD,    // Tiền mặt
        MOMO,   // Ví Momo
        VNPAY   // VNPay
    }

    public enum PaymentStatus {
        PENDING,   // Đang chờ
        SUCCESS,   // Thành công
        FAILED,    // Thất bại
        REFUNDED   // Đã hoàn tiền
    }
}
