package com.grocery.server.product.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * DTO Response: ProductResponse
 * Mục đích: Trả dữ liệu sản phẩm về cho client
 * 
 * Ví dụ JSON:
 * {
 *   "id": 1,
 *   "name": "Thịt ba rọi heo",
 *   "description": "Thịt ba rọi tươi ngon",
 *   "imageUrl": "https://...",
 *   "storeName": "Tạp hóa Cô Ba",
 *   "storeAddress": "123 Nguyễn Văn A, Quận 1",
 *   "categoryName": "Thịt, Cá, Trứng",
 *   "units": [
 *     {
 *       "id": 1,
 *       "unitName": "Gói 300g",
 *       "price": 35000.00,
 *       "stockQuantity": 50
 *     }
 *   ]
 * }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductResponse {
    
    private Long id;
    private String name;
    private String description;
    private String imageUrl;
    private String storeName;
    private String storeAddress;
    private String categoryName;
    private String status;
    
    /**
     * Danh sách đơn vị bán (Gói 300g, Khay 1kg...)
     */
    private List<ProductUnitResponse> units;
    
    /**
     * Nested DTO: ProductUnitResponse
     * Mục đích: Hiển thị các đơn vị bán khác nhau
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ProductUnitResponse {
        private Long id;
        private String unitCode;
        private String unitName;
        private BigDecimal baseQuantity;
        private String baseUnit;
        private Boolean requiresQuantityInput;
        private BigDecimal price;
        private Integer stockQuantity;
        
        /**
         * Trạng thái còn hàng/hết hàng
         */
        public boolean isAvailable() {
            return stockQuantity != null && stockQuantity > 0;
        }
    }
}
