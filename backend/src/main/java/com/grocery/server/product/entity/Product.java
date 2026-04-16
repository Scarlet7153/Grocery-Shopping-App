package com.grocery.server.product.entity;

import com.grocery.server.store.entity.Store;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Entity: products
 * Mô tả: Bảng thông tin chung sản phẩm
 * Lưu ý: Giá và variant nằm ở bảng product_unit_mappings
 */
@Entity
@Table(name = "products")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Thuộc cửa hàng nào
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_id", nullable = false)
    private Store store;

    /**
     * Thuộc danh mục nào
     * VD: Thịt cá, Rau củ, Trái cây...
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    /**
     * Tên sản phẩm
     * VD: "Thịt ba rọi heo", "Rau muống", "Gạo ST25"
     */
    @Column(nullable = false)
    private String name;

    /**
     * Đường dẫn hình ảnh sản phẩm
     */
    @Column(name = "image_url")
    private String imageUrl;

    /**
     * Mô tả chi tiết món hàng
     */
    @Column(columnDefinition = "TEXT")
    private String description;

    /**
     * Tình trạng bán:
     * - AVAILABLE: Còn hàng
     * - OUT_OF_STOCK: Hết hàng
     * - HIDDEN: Ẩn không bán nữa
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ProductStatus status = ProductStatus.AVAILABLE;

    // ========== RELATIONSHIPS ==========

    /**
     * Các đơn vị bán khác nhau của sản phẩm
     * VD: Gói 300g, Khay 1kg, 1 Bó...
     * Sử dụng ProductUnitMapping (bảng product_unit_mappings)
     */
    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<ProductUnitMapping> productUnitMappings;

    // ========== ENUMS ==========

    public enum ProductStatus {
        AVAILABLE,      // Còn hàng
        OUT_OF_STOCK,   // Hết hàng
        HIDDEN          // Ẩn không bán
    }
}
