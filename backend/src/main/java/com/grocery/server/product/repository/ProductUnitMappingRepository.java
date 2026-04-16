package com.grocery.server.product.repository;

import com.grocery.server.product.entity.ProductUnitMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductUnitMappingRepository extends JpaRepository<ProductUnitMapping, Long> {
    
    List<ProductUnitMapping> findByProductId(Long productId);
    
    List<ProductUnitMapping> findByProductIdAndIsActiveTrue(Long productId);
    
    Optional<ProductUnitMapping> findByProductIdAndIsDefaultTrue(Long productId);
    
    List<ProductUnitMapping> findByUnitId(Long unitId);
    
    boolean existsByProductIdAndUnitId(Long productId, Long unitId);
}