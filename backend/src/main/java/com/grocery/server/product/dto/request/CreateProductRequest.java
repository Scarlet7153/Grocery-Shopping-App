package com.grocery.server.product.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO Request: CreateProductRequest
 * Mục đích: Request body để tạo product mới (Store owner only)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateProductRequest {
    
    private Long categoryId;
    
    @NotBlank(message = "Tên sản phẩm không được để trống")
    @Size(min = 2, max = 255, message = "Tên sản phẩm phải từ 2-255 ký tự")
    private String name;
    
    @Size(max = 1000, message = "Mô tả không được vượt quá 1000 ký tự")
    private String description;
    
    private String imageUrl;
    
    @NotEmpty(message = "Phải có ít nhất 1 đơn vị bán")
    @Valid
    private List<ProductUnitRequest> units;
    
    /**
     * Nested DTO cho Product Unit
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ProductUnitRequest {

        @NotBlank(message = "Mã đơn vị không được để trống")
        @Size(max = 50, message = "Mã đơn vị không được vượt quá 50 ký tự")
        private String unitCode;
        
        @NotBlank(message = "Tên đơn vị không được để trống")
        @Size(max = 100, message = "Tên đơn vị không được vượt quá 100 ký tự")
        private String unitName;

        private Double baseQuantity;

        @Size(max = 20, message = "Đơn vị cơ sở không được vượt quá 20 ký tự")
        private String baseUnit;
        
        private Double price;
        
        private Integer stockQuantity;
    }
}
