package com.grocery.server.product.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO Request: UpdateProductRequest
 * Mục đích: Request body để cập nhật product
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateProductRequest {
    
    private Long categoryId;
    
    @Size(min = 2, max = 255, message = "Tên sản phẩm phải từ 2-255 ký tự")
    private String name;
    
    @Size(max = 1000, message = "Mô tả không được vượt quá 1000 ký tự")
    private String description;
    
    private String imageUrl;

    @Valid
    private List<ProductUnitRequest> units;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ProductUnitRequest {

        private Long id;

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

        private Boolean isDefault;

        private Boolean isActive;
    }
}
