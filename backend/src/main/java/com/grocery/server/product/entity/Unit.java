package com.grocery.server.product.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Entity: units
 * Mô tả: Các đơn vị tính cụ thể (kg, gram, bó, quả, vỉ, chai...)
 */
@Entity
@Table(name = "units")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Unit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Thuộc phân loại nào
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private UnitCategory category;

    /**
     * Mã đơn vị: kg, gram, bo, qua, vi, chai
     */
    @Column(nullable = false, unique = true, length = 50)
    private String code;

    /**
     * Tên đơn vị: Kilogram, Bó, Quả, Vỉ
     */
    @Column(nullable = false, length = 100)
    private String name;

    /**
     * Ký hiệu: kg, bó, quả, vỉ
     */
    @Column(nullable = false, length = 20)
    private String symbol;

    /**
     * Đơn vị cơ sở để quy đổi: gram, count, ml, bundle
     */
    @Column(name = "base_unit", length = 20)
    private String baseUnit;

    /**
     * Tỷ lệ quy đổi về đơn vị cơ sở
     * VD: 1 kg = 1000 gram, 1 bó = 300 gram (tùy sản phẩm)
     */
    @Column(name = "conversion_rate", precision = 10, scale = 4)
    @Builder.Default
    private BigDecimal conversionRate = BigDecimal.ONE;

    /**
     * Bước nhảy khi tăng/giảm số lượng
     * VD: 0.5 cho lạng, 1 cho quả, 0.1 cho kg
     */
    @Column(name = "step_value", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal stepValue = BigDecimal.ONE;

    /**
     * TRUE: cần nhập độ lớn (vd 500g, 1.5kg)
     * FALSE: đơn vị đếm cố định (vd bó, khay, lon)
     */
    @Column(name = "requires_quantity_input")
    @Builder.Default
    private Boolean requiresQuantityInput = false;

    /**
     * Giá trị tối thiểu
     */
    @Column(name = "min_value", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal minValue = BigDecimal.ZERO;

    /**
     * Giá trị tối đa
     */
    @Column(name = "max_value", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal maxValue = new BigDecimal("999999");

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
    @OneToMany(mappedBy = "unit", cascade = CascadeType.ALL)
    private List<ProductUnitMapping> productMappings;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    /**
     * Helper method: Lấy tên phân loại
     */
    public String getCategoryName() {
        return category != null ? category.getName() : "";
    }

    /**
     * Helper method: Lấy icon phân loại
     */
    public String getCategoryIcon() {
        return category != null ? category.getIcon() : "";
    }
}