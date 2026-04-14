package com.grocery.server.product.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Entity: unit_categories
 * Mô tả: Phân loại đơn vị tính (Khối lượng, Số lượng, Bó/Mớ, Thể tích)
 */
@Entity
@Table(name = "unit_categories")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UnitCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Mã phân loại: weight, count, bundle, volume
     */
    @Column(nullable = false, unique = true, length = 50)
    private String code;

    /**
     * Tên hiển thị: Khối lượng, Số lượng, Bó/Mớ, Thể tích
     */
    @Column(nullable = false, length = 100)
    private String name;

    /**
     * Icon Material
     */
    @Column(length = 50)
    private String icon;

    /**
     * Thứ tự hiển thị
     */
    @Column(name = "display_order")
    @Builder.Default
    private Integer displayOrder = 0;

    /**
     * Trạng thái hoạt động
     */
    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // Relationships
    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL)
    private List<Unit> units;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}