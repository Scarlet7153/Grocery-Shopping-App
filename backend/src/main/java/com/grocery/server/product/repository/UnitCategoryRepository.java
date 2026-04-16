package com.grocery.server.product.repository;

import com.grocery.server.product.entity.UnitCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UnitCategoryRepository extends JpaRepository<UnitCategory, Long> {
    
    Optional<UnitCategory> findByCode(String code);
    
    List<UnitCategory> findByIsActiveTrueOrderByDisplayOrderAsc();
    
    boolean existsByCode(String code);
}