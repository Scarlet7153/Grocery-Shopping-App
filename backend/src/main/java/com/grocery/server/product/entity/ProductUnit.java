package com.grocery.server.product.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Entity: product_units
 * Mô tả: Bảng đơn vị & giá bán
 * 
 * Giải thích: 
 * 1 sản phẩm có thể có nhiều đơn vị bán khác nhau
 * VD: "Thịt ba rọi" có thể bán theo:
 *   - Gói 300g: 35,000đ
 *   - Khay 1kg: 110,000đ
 *   - 500g: 55,000đ
 */
@Entity
@Table(name = "product_units")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductUnit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Thuộc về sản phẩm nào
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    /**
     * Tên đơn vị bán
     * VD: "Gói 300g", "1 Bó", "Khay 1kg", "1 Chai 1L"
     */
    @Column(name = "unit_name", nullable = false, length = 50)
    private String unitName;

    /**
     * Giá / Đơn vị (VNĐ)
     * VD: 35000 (35,000 đồng)
     */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    /**
     * Số lượng còn lại trong kho của đơn vị này
     */
    @Column(name = "stock_quantity", nullable = false)
    @Builder.Default
    private Integer stockQuantity = 0;

    // ========== RELATIONSHIPS ==========

}
