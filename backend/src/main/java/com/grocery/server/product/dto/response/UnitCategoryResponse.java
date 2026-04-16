package com.grocery.server.product.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnitCategoryResponse {
    private Long id;
    private String code;
    private String name;
    private String icon;
    private Integer displayOrder;
    private Boolean isActive;
}