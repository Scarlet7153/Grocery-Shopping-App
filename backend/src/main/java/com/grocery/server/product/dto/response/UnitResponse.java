package com.grocery.server.product.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnitResponse {
    private Long id;
    private String code;
    private String name;
    private String symbol;
    private String baseUnit;
    private BigDecimal conversionRate;
    private BigDecimal stepValue;
    private Boolean requiresQuantityInput;
    private BigDecimal minValue;
    private BigDecimal maxValue;
    private Integer displayOrder;
    private Boolean isActive;
    private UnitCategoryResponse category;
}