package com.grocery.server.product.repository;

import com.grocery.server.product.entity.Unit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UnitRepository extends JpaRepository<Unit, Long> {
    
    Optional<Unit> findByCode(String code);

    Optional<Unit> findByNameIgnoreCase(String name);

    Optional<Unit> findBySymbolIgnoreCase(String symbol);
    
    List<Unit> findByCategoryId(Long categoryId);
    
    List<Unit> findByIsActiveTrueOrderByDisplayOrderAsc();
    
    List<Unit> findByCategoryIdAndIsActiveTrueOrderByDisplayOrderAsc(Long categoryId);
    
    boolean existsByCode(String code);
}