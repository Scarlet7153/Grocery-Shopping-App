package com.grocery.server.product.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Runtime migration: allow multiple product variants with the same standard unit.
 * Old schema had UNIQUE(product_id, unit_id), which blocks cases like 300g and 500g.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ProductUnitMappingConstraintMigration implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        try {
            jdbcTemplate.execute("ALTER TABLE product_unit_mappings DROP INDEX uk_product_unit");
            log.info("Dropped unique index uk_product_unit on product_unit_mappings");
        } catch (Exception ex) {
            log.debug("Skip drop uk_product_unit (may not exist): {}", ex.getMessage());
        }

        try {
            jdbcTemplate.execute("CREATE INDEX idx_product_unit ON product_unit_mappings(product_id, unit_id)");
            log.info("Created non-unique index idx_product_unit on product_unit_mappings");
        } catch (Exception ex) {
            log.debug("Skip create idx_product_unit (may already exist): {}", ex.getMessage());
        }
    }
}
