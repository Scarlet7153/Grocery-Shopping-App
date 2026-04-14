package com.grocery.server.product.controller;

import com.grocery.server.product.dto.response.UnitCategoryResponse;
import com.grocery.server.product.dto.response.UnitResponse;
import com.grocery.server.product.entity.Unit;
import com.grocery.server.product.entity.UnitCategory;
import com.grocery.server.product.repository.UnitCategoryRepository;
import com.grocery.server.product.repository.UnitRepository;
import com.grocery.server.shared.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/units")
@RequiredArgsConstructor
public class UnitController {

    private final UnitRepository unitRepository;
    private final UnitCategoryRepository unitCategoryRepository;

    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<UnitCategoryResponse>>> getAllCategories() {
        List<UnitCategoryResponse> categories = unitCategoryRepository.findByIsActiveTrueOrderByDisplayOrderAsc()
                .stream()
                .map(this::mapToCategoryResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(categories));
    }

    @GetMapping("/categories/{categoryId}/units")
    public ResponseEntity<ApiResponse<List<UnitResponse>>> getUnitsByCategory(@PathVariable Long categoryId) {
        List<UnitResponse> units = unitRepository.findByCategoryIdAndIsActiveTrueOrderByDisplayOrderAsc(categoryId)
                .stream()
                .map(this::mapToUnitResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(units));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<UnitResponse>>> getAllUnits() {
        List<UnitResponse> units = unitRepository.findByIsActiveTrueOrderByDisplayOrderAsc()
                .stream()
                .map(this::mapToUnitResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(units));
    }

    @GetMapping("/{code}")
    public ResponseEntity<ApiResponse<UnitResponse>> getUnitByCode(@PathVariable String code) {
        return unitRepository.findByCode(code)
                .map(unit -> ResponseEntity.ok(ApiResponse.success(mapToUnitResponse(unit))))
                .orElse(ResponseEntity.notFound().build());
    }

    private UnitCategoryResponse mapToCategoryResponse(UnitCategory category) {
        return UnitCategoryResponse.builder()
                .id(category.getId())
                .code(category.getCode())
                .name(category.getName())
                .icon(category.getIcon())
                .displayOrder(category.getDisplayOrder())
                .isActive(category.getIsActive())
                .build();
    }

    private UnitResponse mapToUnitResponse(Unit unit) {
        return UnitResponse.builder()
                .id(unit.getId())
                .code(unit.getCode())
                .name(unit.getName())
                .symbol(unit.getSymbol())
                .baseUnit(unit.getBaseUnit())
                .conversionRate(unit.getConversionRate())
                .stepValue(unit.getStepValue())
                .requiresQuantityInput(Boolean.TRUE.equals(unit.getRequiresQuantityInput()))
                .minValue(unit.getMinValue())
                .maxValue(unit.getMaxValue())
                .displayOrder(unit.getDisplayOrder())
                .isActive(unit.getIsActive())
                .category(mapToCategoryResponse(unit.getCategory()))
                .build();
    }
}