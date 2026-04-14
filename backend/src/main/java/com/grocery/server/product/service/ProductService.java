package com.grocery.server.product.service;

import com.grocery.server.product.dto.request.CreateProductRequest;
import com.grocery.server.product.dto.request.UpdateProductRequest;
import com.grocery.server.product.dto.response.ProductResponse;
import com.grocery.server.product.entity.Category;
import com.grocery.server.product.entity.Product;
import com.grocery.server.product.entity.ProductUnitMapping;
import com.grocery.server.product.entity.Unit;
import com.grocery.server.product.repository.CategoryRepository;
import com.grocery.server.product.repository.ProductRepository;
import com.grocery.server.product.repository.UnitRepository;
import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service: ProductService
 * Mục đích: Xử lý business logic cho Product management
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductService {
    
    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final StoreRepository storeRepository;
    private final UnitRepository unitRepository;
    private final UserRepository userRepository;
    
    /**
     * Lấy tất cả products (Public)
     */
    public List<ProductResponse> getAllProducts() {
        // Sử dụng JOIN FETCH để lấy cả units trong 1 query
        List<Product> products = productRepository.findAllWithUnits();
        log.info("Get all products, total: {}", products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy products theo store ID (Public)
     */
    public List<ProductResponse> getProductsByStore(Long storeId) {
        // Sử dụng JOIN FETCH để lấy cả units trong 1 query
        List<Product> products = productRepository.findByStoreIdWithUnits(storeId);
        log.info("Get products by store: {}, total: {}", storeId, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy products theo category ID (Public)
     */
    public List<ProductResponse> getProductsByCategory(Long categoryId) {
        // Kiểm tra category có tồn tại không
        categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));
        
        List<Product> products = productRepository.findByCategoryId(categoryId);
        log.info("Get products by category: {}, total: {}", categoryId, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy products đang available theo store (Public)
     */
    public List<ProductResponse> getAvailableProductsByStore(Long storeId) {
        List<Product> products = productRepository.findAvailableProductsByStore(storeId);
        log.info("Get available products by store: {}, total: {}", storeId, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Tìm kiếm products theo keyword (Public)
     */
    public List<ProductResponse> searchProducts(String keyword) {
        List<Product> products = productRepository.searchByKeyword(keyword);
        log.info("Search products with keyword: '{}', found: {}", keyword, products.size());
        
        return products.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }
    
    /**
     * Lấy product theo ID (Public)
     */
    public ProductResponse getProductById(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        log.info("Get product by ID: {}", productId);
        return convertToResponse(product);
    }
    
    /**
     * Tạo product mới (Store owner only)
     */
    @Transactional
    public ProductResponse createProduct(CreateProductRequest request) {
        User currentUser = getCurrentUser();
        
        // Lấy store của user hiện tại
        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new BadRequestException("Bạn chưa có cửa hàng"));
        
        // Kiểm tra category nếu có
        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.getCategoryId()));
        }
        
        // Tạo product
        Product product = Product.builder()
                .store(store)
                .category(category)
                .name(request.getName())
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .status(Product.ProductStatus.AVAILABLE)
                .build();
        
        // Tạo mapping đơn vị bán cho sản phẩm
        List<ProductUnitMapping> mappings = new ArrayList<>();
        for (int i = 0; i < request.getUnits().size(); i++) {
            CreateProductRequest.ProductUnitRequest unitReq = request.getUnits().get(i);
            Unit resolvedUnit = resolveUnit(unitReq.getUnitCode(), unitReq.getUnitName());
            Double inputQuantity = unitReq.getBaseQuantity();
            BigDecimal baseQuantity = resolveBaseQuantity(inputQuantity, resolvedUnit);
            String baseUnit = resolveBaseUnit(unitReq.getBaseUnit(), resolvedUnit, baseQuantity);
            String unitLabel = resolveUnitLabel(unitReq.getUnitName(), resolvedUnit, inputQuantity);

            ProductUnitMapping mapping = ProductUnitMapping.builder()
                .product(product)
                .unit(resolvedUnit)
                .unitLabel(unitLabel)
                .baseQuantity(baseQuantity)
                .baseUnit(baseUnit)
                .price(BigDecimal.valueOf(unitReq.getPrice()))
                .stockQuantity(unitReq.getStockQuantity() != null ? unitReq.getStockQuantity() : 0)
                .isDefault(i == 0)
                .isActive(true)
                .build();
            mappings.add(mapping);
        }

        product.setProductUnitMappings(mappings);
        
        Product savedProduct = productRepository.save(product);
        log.info("Created new product: {} for store: {}", savedProduct.getName(), store.getStoreName());
        
        return convertToResponse(savedProduct);
    }
    
    /**
     * Cập nhật product (Store owner only)
     */
    @Transactional
    public ProductResponse updateProduct(Long productId, UpdateProductRequest request) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền: chỉ owner mới được cập nhật
        if (!product.getStore().getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền cập nhật sản phẩm này");
        }
        
        // Cập nhật thông tin
        if (request.getName() != null && !request.getName().trim().isEmpty()) {
            product.setName(request.getName());
        }
        
        if (request.getDescription() != null) {
            product.setDescription(request.getDescription());
        }
        
        if (request.getImageUrl() != null) {
            product.setImageUrl(request.getImageUrl());
        }
        
        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.getCategoryId()));
            product.setCategory(category);
        }

        if (request.getUnits() != null && !request.getUnits().isEmpty()) {
            if (product.getProductUnitMappings() == null) {
                product.setProductUnitMappings(new ArrayList<>());
            }

            Map<Long, ProductUnitMapping> existingById = new HashMap<>();
            for (ProductUnitMapping existingMapping : product.getProductUnitMappings()) {
                if (existingMapping.getId() != null) {
                    existingById.put(existingMapping.getId(), existingMapping);
                }
            }

            List<ProductUnitMapping> nextMappings = new ArrayList<>();

            for (int i = 0; i < request.getUnits().size(); i++) {
                UpdateProductRequest.ProductUnitRequest unitReq = request.getUnits().get(i);
                Unit resolvedUnit = resolveUnit(unitReq.getUnitCode(), unitReq.getUnitName());
                Double inputQuantity = unitReq.getBaseQuantity();
                BigDecimal baseQuantity = resolveBaseQuantity(inputQuantity, resolvedUnit);
                String baseUnit = resolveBaseUnit(unitReq.getBaseUnit(), resolvedUnit, baseQuantity);
                String unitLabel = resolveUnitLabel(unitReq.getUnitName(), resolvedUnit, inputQuantity);

                ProductUnitMapping mapping = null;
                if (unitReq.getId() != null && unitReq.getId() > 0) {
                    mapping = existingById.get(unitReq.getId());
                }
                if (mapping == null) {
                    mapping = ProductUnitMapping.builder()
                            .product(product)
                            .unit(resolvedUnit)
                            .build();
                } else {
                    mapping.setUnit(resolvedUnit);
                }

                mapping.setUnitLabel(unitLabel);
                mapping.setBaseQuantity(baseQuantity);
                mapping.setBaseUnit(baseUnit);
                mapping.setPrice(BigDecimal.valueOf(unitReq.getPrice() != null ? unitReq.getPrice() : 0));
                mapping.setStockQuantity(unitReq.getStockQuantity() != null ? unitReq.getStockQuantity() : 0);
                mapping.setIsDefault(Boolean.TRUE.equals(unitReq.getIsDefault()) || i == 0);
                mapping.setIsActive(unitReq.getIsActive() == null || unitReq.getIsActive());

                nextMappings.add(mapping);
            }

            product.getProductUnitMappings().clear();
            product.getProductUnitMappings().addAll(nextMappings);
        }
        
        Product updatedProduct = productRepository.save(product);
        log.info("Updated product: {}", productId);
        
        return convertToResponse(updatedProduct);
    }
    
    /**
     * Toggle product status (Store owner only)
     */
    @Transactional
    public ProductResponse toggleProductStatus(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền
        if (!product.getStore().getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền thay đổi trạng thái sản phẩm này");
        }
        
        // Toggle status
        if (product.getStatus() == Product.ProductStatus.AVAILABLE) {
            product.setStatus(Product.ProductStatus.HIDDEN);
        } else {
            product.setStatus(Product.ProductStatus.AVAILABLE);
        }
        
        Product updatedProduct = productRepository.save(product);
        log.info("Toggled product status: {} to {}", productId, updatedProduct.getStatus());
        
        return convertToResponse(updatedProduct);
    }
    
    /**
     * Xóa product (Store owner only)
     */
    @Transactional
    public void deleteProduct(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền
        if (!product.getStore().getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền xóa sản phẩm này");
        }
        
        productRepository.delete(product);
        log.info("Deleted product: {}", productId);
    }
    
    /**
     * Helper: Convert Product entity to ProductResponse DTO
     */
    private ProductResponse convertToResponse(Product product) {
        // Lấy danh sách productUnitMappings và chuyển đổi sang response
        List<ProductUnitMapping> mappings = product.getProductUnitMappings();
        if (mappings == null) {
            mappings = new ArrayList<>();
        }
        
        List<ProductResponse.ProductUnitResponse> unitResponses = mappings.stream()
                .filter(mapping -> mapping != null && mapping.getIsActive())
                .map(mapping -> ProductResponse.ProductUnitResponse.builder()
                        .id(mapping.getId())
                    .unitCode(mapping.getUnit() != null ? mapping.getUnit().getCode() : null)
                        .unitName(mapping.getUnitLabel() != null ? mapping.getUnitLabel() : 
                                  (mapping.getUnit() != null ? mapping.getUnit().getName() : ""))
                    .baseQuantity(mapping.getBaseQuantity())
                    .baseUnit(mapping.getBaseUnit())
                    .requiresQuantityInput(mapping.getUnit() != null
                        && Boolean.TRUE.equals(mapping.getUnit().getRequiresQuantityInput()))
                        .price(mapping.getPrice())
                        .stockQuantity(mapping.getStockQuantity())
                        .build())
                .collect(Collectors.toList());
        
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .description(product.getDescription())
                .imageUrl(product.getImageUrl())
                .storeName(product.getStore().getStoreName())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .status(product.getStatus().name())
                .units(unitResponses)
                .build();
    }

    private Unit resolveUnit(String unitCode, String unitLabel) {
        if (unitCode != null && !unitCode.isBlank()) {
            return unitRepository.findByCode(unitCode.trim().toLowerCase())
                    .orElseThrow(() -> new ResourceNotFoundException("Unit", "code", unitCode));
        }

        if (unitLabel == null || unitLabel.isBlank()) {
            return unitRepository.findByCode("kg")
                    .orElseThrow(() -> new ResourceNotFoundException("Unit", "code", "kg"));
        }

        String normalized = unitLabel.trim().toLowerCase();
        String code = switch (normalized) {
            case "kg", "kilogram" -> "kg";
            case "g", "gram", "gam" -> "gram";
            case "lang", "lạng" -> "lang";
            case "bo", "bó" -> "bo";
            case "goi", "gói" -> "goi";
            case "chai" -> "chai";
            case "lon" -> "lon";
            default -> normalized;
        };

        return unitRepository.findByCode(code)
                .or(() -> unitRepository.findByNameIgnoreCase(unitLabel.trim()))
                .or(() -> unitRepository.findBySymbolIgnoreCase(unitLabel.trim()))
                .orElseGet(() -> unitRepository.findByCode("kg")
                        .orElseThrow(() -> new ResourceNotFoundException("Unit", "code", "kg")));
    }

    private BigDecimal resolveBaseQuantity(Double requestedBaseQuantity, Unit unit) {
        boolean requiresInput = Boolean.TRUE.equals(unit.getRequiresQuantityInput());
        if (!requiresInput) {
            if (requestedBaseQuantity == null || requestedBaseQuantity <= 0) {
                return null;
            }
            return BigDecimal.valueOf(requestedBaseQuantity).setScale(4, RoundingMode.HALF_UP);
        }

        if (requestedBaseQuantity == null || requestedBaseQuantity <= 0) {
            throw new BadRequestException(
                    "Đơn vị " + unit.getName() + " yêu cầu nhập độ lớn (baseQuantity > 0)");
        }

        BigDecimal inputQuantity = BigDecimal.valueOf(requestedBaseQuantity);
        BigDecimal conversionRate = unit.getConversionRate() != null
                ? unit.getConversionRate()
                : BigDecimal.ONE;
        if (conversionRate.compareTo(BigDecimal.ZERO) <= 0) {
            conversionRate = BigDecimal.ONE;
        }
        return inputQuantity.multiply(conversionRate).setScale(4, RoundingMode.HALF_UP);
    }

    private String resolveBaseUnit(String requestedBaseUnit, Unit unit, BigDecimal baseQuantity) {
        if (requestedBaseUnit != null && !requestedBaseUnit.isBlank()) {
            return requestedBaseUnit.trim();
        }
        if (baseQuantity != null && unit.getBaseUnit() != null && !unit.getBaseUnit().isBlank()) {
            return unit.getBaseUnit();
        }
        return null;
    }

    private String resolveUnitLabel(String requestedLabel, Unit unit, Double inputQuantity) {
        boolean requiresInput = Boolean.TRUE.equals(unit.getRequiresQuantityInput());
        if (requiresInput) {
            if (inputQuantity == null || inputQuantity <= 0) {
                throw new BadRequestException(
                        "Đơn vị " + unit.getName() + " yêu cầu nhập độ lớn để tạo nhãn");
            }
            return formatQuantity(BigDecimal.valueOf(inputQuantity)) + unit.getSymbol();
        }
        if (requestedLabel != null && !requestedLabel.isBlank()) {
            return requestedLabel.trim();
        }
        throw new BadRequestException("Đơn vị " + unit.getName() + " yêu cầu nhập nhãn hiển thị");
    }

    private String formatQuantity(BigDecimal value) {
        DecimalFormat df = new DecimalFormat("0.####");
        return df.format(value);
    }
    
    /**
     * Helper: Lấy current user từ SecurityContext
     */
    private User getCurrentUser() {
        String phoneNumber = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ResourceNotFoundException("User", "phoneNumber", phoneNumber));
    }
}
