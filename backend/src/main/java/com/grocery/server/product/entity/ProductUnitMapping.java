package com.grocery.server.product.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entity: product_unit_mappings
 * Mô tả: Liên kết sản phẩm với đơn vị bán, giá và tồn kho
 * 
 * 1 sản phẩm có thể có nhiều đơn vị bán khác nhau với giá khác nhau
 */
@Entity
@Table(name = "product_unit_mappings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductUnitMapping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Thuộc sản phẩm nào
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    /**
     * Sử dụng đơn vị nào
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id", nullable = false)
    private Unit unit;

    /**
     * Label hiển thị tùy chỉnh: "Gói 300g", "Bó lớn"
     * Nếu null thì dùng unit.name
     */
    @Column(name = "unit_label", length = 100)
    private String unitLabel;

    /**
     * Giá bán theo đơn vị này (VNĐ)
     */
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    /**
     * Số lượng tồn kho
     */
    @Column(name = "stock_quantity", nullable = false)
    @Builder.Default
    private Integer stockQuantity = 0;

    /**
     * Quy đổi về đơn vị cơ sở
     * VD: 1 bó = 300 gram
     */
    @Column(name = "base_quantity", precision = 10, scale = 4)
    private BigDecimal baseQuantity;

    /**
     * Đơn vị cơ sở: gram, count
     */
    @Column(name = "base_unit", length = 20)
    private String baseUnit;

    /**
     * Có phải đơn vị mặc định không
     */
    @Column(name = "is_default")
    @Builder.Default
    private Boolean isDefault = false;

    /**
     * Còn đang sử dụng không
     */
    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    /**
     * Helper: Lấy tên đơn vị hiển thị
     */
    public String getDisplayUnitName() {
        if (unitLabel != null && !unitLabel.isEmpty()) {
            return unitLabel;
        }
        return unit != null ? unit.getName() : "";
    }

    /**
     * Helper: Lấy symbol đơn vị
     */
    public String getUnitSymbol() {
        return unit != null ? unit.getSymbol() : "";
    }

    /**
     * Helper: Lấy step value cho UI
     */
    public BigDecimal getStepValue() {
        return unit != null ? unit.getStepValue() : BigDecimal.ONE;
    }

    /**
     * Helper: Lấy category code
     */
    public String getCategoryCode() {
        return unit != null && unit.getCategory() != null 
            ? unit.getCategory().getCode() 
            : "";
    }
}