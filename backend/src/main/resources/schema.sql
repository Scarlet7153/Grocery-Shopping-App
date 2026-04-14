-- =========================================================
-- GROCERY SHOPPING APP - DATABASE SCHEMA
-- Version: 2.2
-- Updated: April 2026
-- Key change: product_unit_mappings là bảng VARIANT
--   - Bỏ UNIQUE(product_id, unit_id) → 1 product có nhiều
--     variant cùng loại đơn vị (VD: Gói 300g, Gói 500g)
--   - unit_id = loại đo lường (Gram, Kg, Bó...)  → dropdown
--   - unit_label = nhãn hiển thị (300g, 500g...) → text input
--   - base_quantity = số lượng quy đổi           → tính toán
-- =========================================================

DROP DATABASE IF EXISTS grocery_db;
CREATE DATABASE grocery_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE grocery_db;

-- =========================================================
-- 1. Table: users
-- =========================================================
CREATE TABLE users (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone_number  VARCHAR(15)  UNIQUE NOT NULL COMMENT 'Số điện thoại đăng nhập',
    password_hash VARCHAR(255) NOT NULL         COMMENT 'BCrypt hash',
    role          ENUM('CUSTOMER','SHIPPER','STORE','ADMIN') NOT NULL,
    status        ENUM('ACTIVE','BANNED','PENDING') DEFAULT 'ACTIVE',
    full_name     VARCHAR(100),
    avatar_url    VARCHAR(255),
    address       VARCHAR(255),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone  (phone_number),
    INDEX idx_role   (role),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Người dùng (Khách, Shipper, Cửa hàng, Admin)';

-- =========================================================
-- 2. Table: stores
-- =========================================================
CREATE TABLE stores (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id    BIGINT       NOT NULL COMMENT 'Chủ cửa hàng',
    store_name VARCHAR(100) NOT NULL,
    address    VARCHAR(255) NOT NULL,
    is_open    BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_open (is_open)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Cửa hàng';

-- =========================================================
-- 3. Table: categories
-- =========================================================
CREATE TABLE categories (
    id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    icon_url VARCHAR(255),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Danh mục sản phẩm';

-- =========================================================
-- 4. Table: unit_categories
-- =========================================================
CREATE TABLE unit_categories (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    code          VARCHAR(50)  NOT NULL UNIQUE COMMENT 'weight | count | bundle | volume',
    name          VARCHAR(100) NOT NULL         COMMENT 'Khối lượng | Số lượng | Bó/Gói | Thể tích',
    icon          VARCHAR(50)                   COMMENT 'Material icon name',
    display_order INT     DEFAULT 0,
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Nhóm đơn vị tính';

-- =========================================================
-- 5. Table: units
-- Đây là danh sách đơn vị đo lường CHUẨN hiển thị trong dropdown.
-- Mỗi unit chỉ xuất hiện 1 lần (kg, gram, bó, chai...).
-- Không cần tạo thêm kg_lon, goi_nho... vì variant được xử lý
-- ở tầng product_unit_mappings.
-- =========================================================
CREATE TABLE units (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_id     BIGINT      NOT NULL,
    code            VARCHAR(50) NOT NULL UNIQUE COMMENT 'kg | gram | lang | bo | goi | ...',
    name            VARCHAR(100) NOT NULL       COMMENT 'Tên hiển thị trong dropdown',
    symbol          VARCHAR(20)  NOT NULL       COMMENT 'Ký hiệu ngắn: kg, g, bó...',
    base_unit       VARCHAR(20)                 COMMENT 'Đơn vị quy đổi gốc: gram | count | ml | bundle',
    conversion_rate DECIMAL(10,4) DEFAULT 1.0000 COMMENT 'Hệ số quy đổi về base_unit',
    step_value      DECIMAL(10,2) DEFAULT 1.00   COMMENT 'Bước nhảy +/- trên UI',
    -- Flag quan trọng cho UI:
    -- TRUE  → hiện ô "Nhập độ lớn" khi chọn đơn vị này (gram, kg, lạng, ml, lít)
    --         unit_label sẽ tự ghép: {quantity}{symbol} → "500g", "1.5kg"
    -- FALSE → không cần ô nhập, đơn vị đã rõ nghĩa (bó, khay, gói, lon...)
    --         số lượng chỉ nhập ở trang đặt hàng
    requires_quantity_input BOOLEAN DEFAULT FALSE COMMENT 'TRUE=cần nhập độ lớn (gram/kg/ml); FALSE=đơn vị cố định (bó/khay/lon)',

    display_order   INT     DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES unit_categories(id),
    INDEX idx_category_id (category_id),
    INDEX idx_code        (code),
    INDEX idx_is_active   (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Đơn vị đo lường chuẩn (hiển thị trong dropdown)';

-- =========================================================
-- 6. Table: products
-- =========================================================
CREATE TABLE products (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    store_id    BIGINT       NOT NULL,
    category_id BIGINT,
    name        VARCHAR(255) NOT NULL,
    image_url   VARCHAR(255),
    description TEXT,
    status      ENUM('AVAILABLE','OUT_OF_STOCK','HIDDEN') DEFAULT 'AVAILABLE',
    FOREIGN KEY (store_id)    REFERENCES stores(id)     ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_store_id    (store_id),
    INDEX idx_category_id (category_id),
    INDEX idx_status      (status),
    FULLTEXT INDEX ft_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Sản phẩm';

-- =========================================================
-- 7. Table: product_unit_mappings  ← BẢNG VARIANT
--
-- Mỗi row = 1 biến thể bán của sản phẩm.
-- VD: Thịt ba rọi có 3 row:
--   row 1: unit_id=gram, unit_label='300g', price=35000, base_quantity=300
--   row 2: unit_id=gram, unit_label='500g', price=55000, base_quantity=500
--   row 3: unit_id=kg,   unit_label='1kg',  price=110000, base_quantity=1000
--
-- KHÔNG có UNIQUE(product_id, unit_id) vì cùng đơn vị
-- có thể có nhiều size khác nhau.
-- =========================================================
CREATE TABLE product_unit_mappings (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id     BIGINT       NOT NULL,
    unit_id        BIGINT       NOT NULL  COMMENT 'Đơn vị chuẩn (FK units.id) — hiện trong dropdown',

    -- Thông tin variant
    unit_label     VARCHAR(100) NOT NULL  COMMENT 'Nhãn hiển thị: 300g | Gói 500g | 1 Nải | Thùng 24',
    price          DECIMAL(12,2) NOT NULL COMMENT 'Giá bán của variant này',
    stock_quantity INT NOT NULL DEFAULT 0 COMMENT 'Tồn kho của variant này',

    -- Quy đổi về đơn vị gốc (phục vụ tính toán)
    base_quantity  DECIMAL(10,4)          COMMENT 'Số lượng quy đổi: 300 (gram), 1 (bundle)...',
    base_unit      VARCHAR(20)            COMMENT 'gram | count | ml | bundle',

    -- Thứ tự & trạng thái
    sort_order     INT     DEFAULT 0      COMMENT 'Thứ tự hiển thị trong danh sách variant',
    is_default     BOOLEAN DEFAULT FALSE  COMMENT 'Variant mặc định khi mở trang sản phẩm',
    is_active      BOOLEAN DEFAULT TRUE,

    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (unit_id)    REFERENCES units(id),

    -- Không UNIQUE(product_id, unit_id) — cho phép nhiều variant cùng loại đơn vị
    INDEX idx_product_id  (product_id),
    INDEX idx_unit_id     (unit_id),
    INDEX idx_is_default  (is_default),
    INDEX idx_sort_order  (product_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Variant bán của sản phẩm (nhiều size/loại trên cùng 1 sản phẩm)';

-- =========================================================
-- 8. Table: orders
-- =========================================================
CREATE TABLE orders (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id      BIGINT       NOT NULL,
    store_id         BIGINT       NOT NULL,
    shipper_id       BIGINT       DEFAULT NULL,
    status           ENUM('PENDING','CONFIRMED','PICKING_UP','DELIVERING','DELIVERED','CANCELLED')
                         DEFAULT 'PENDING',
    total_amount     DECIMAL(10,2) NOT NULL,
    shipping_fee     DECIMAL(10,2) NOT NULL,
    delivery_address VARCHAR(255)  NOT NULL,
    pod_image_url    VARCHAR(255)  DEFAULT NULL COMMENT 'Ảnh bằng chứng giao hàng',
    cancel_reason    VARCHAR(255)  DEFAULT NULL,
    payment_status   ENUM('PENDING','SUCCESS','FAILED') DEFAULT 'PENDING',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(id),
    FOREIGN KEY (store_id)    REFERENCES stores(id),
    FOREIGN KEY (shipper_id)  REFERENCES users(id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_store_id    (store_id),
    INDEX idx_shipper_id  (shipper_id),
    INDEX idx_status      (status),
    INDEX idx_created_at  (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Đơn hàng';

-- =========================================================
-- 9. Table: order_items
-- =========================================================
CREATE TABLE order_items (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id                BIGINT        NOT NULL,
    product_unit_mapping_id BIGINT        NOT NULL COMMENT 'Variant đã mua',
    quantity                DECIMAL(10,2) NOT NULL COMMENT 'Số lượng (có thể là 0.5 lạng)',
    unit_price              DECIMAL(10,2) NOT NULL COMMENT 'Đơn giá tại thời điểm mua',
    FOREIGN KEY (order_id)                REFERENCES orders(id)               ON DELETE CASCADE,
    FOREIGN KEY (product_unit_mapping_id) REFERENCES product_unit_mappings(id),
    INDEX idx_order_id                (order_id),
    INDEX idx_product_unit_mapping_id (product_unit_mapping_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Chi tiết đơn hàng';

-- =========================================================
-- 10. Table: payments
-- =========================================================
CREATE TABLE payments (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id         BIGINT       NOT NULL,
    payment_method   ENUM('COD','MOMO','VNPAY') NOT NULL,
    amount           DECIMAL(10,2) NOT NULL,
    transaction_code VARCHAR(100)  DEFAULT NULL,
    status           ENUM('PENDING','SUCCESS','FAILED','REFUNDED') DEFAULT 'PENDING',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    INDEX idx_order_id       (order_id),
    INDEX idx_payment_method (payment_method),
    INDEX idx_status         (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Lịch sử thanh toán';

-- =========================================================
-- 11. Table: reviews
-- =========================================================
CREATE TABLE reviews (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id    BIGINT   NOT NULL,
    reviewer_id BIGINT   NOT NULL,
    store_id    BIGINT   NOT NULL,
    rating      TINYINT  CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id)    REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(id),
    FOREIGN KEY (store_id)    REFERENCES stores(id),
    INDEX idx_order_id    (order_id),
    INDEX idx_reviewer_id (reviewer_id),
    INDEX idx_store_id    (store_id),
    INDEX idx_rating      (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Đánh giá cửa hàng';

-- =========================================================
-- SAMPLE DATA
-- =========================================================

-- Unit categories
INSERT INTO unit_categories (code, name, icon, display_order) VALUES
('weight', 'Khối lượng',  'scale',                1),
('count',  'Số lượng',    'format_list_numbered', 2),
('bundle', 'Bó/Gói/Túi', 'inventory_2',          3),
('volume', 'Thể tích',    'local_drink',          4);

-- Units (dropdown options — mỗi loại đo lường chỉ 1 row, KHÔNG có lon/goi_lon workaround)
-- Columns: category_id, code, name, symbol, base_unit, conversion_rate, step_value, requires_quantity_input, display_order
INSERT INTO units (category_id, code, name, symbol, base_unit, conversion_rate, step_value, requires_quantity_input, display_order) VALUES
-- Khối lượng — cần nhập độ lớn (500 gram, 1.5 kg...)
((SELECT id FROM unit_categories WHERE code='weight'), 'kg',   'Kilogram', 'kg',   'gram', 1000.0000, 0.50, TRUE, 1),
((SELECT id FROM unit_categories WHERE code='weight'), 'gram', 'Gram',     'g',    'gram',    1.0000, 50.00, TRUE, 2),
((SELECT id FROM unit_categories WHERE code='weight'), 'lang', 'Lạng',     'lạng', 'gram',  100.0000, 0.50, TRUE, 3),

-- Số lượng — không cần nhập độ lớn, đặt hàng mới nhập số lượng
((SELECT id FROM unit_categories WHERE code='count'), 'qua', 'Quả/Trái', 'quả', 'count', 1.0000, 1.00, FALSE, 1),
((SELECT id FROM unit_categories WHERE code='count'), 'con', 'Con',      'con', 'count', 1.0000, 1.00, FALSE, 2),
((SELECT id FROM unit_categories WHERE code='count'), 'vi',  'Vỉ',       'vỉ',  'count', 1.0000, 1.00, FALSE, 3),

-- Bó/Gói/Túi — không cần nhập độ lớn
((SELECT id FROM unit_categories WHERE code='bundle'), 'bo',   'Bó',   'bó',   'bundle', 1.0000, 1.00, FALSE, 1),
((SELECT id FROM unit_categories WHERE code='bundle'), 'goi',  'Gói',  'gói',  'bundle', 1.0000, 1.00, FALSE, 2),
((SELECT id FROM unit_categories WHERE code='bundle'), 'tui',  'Túi',  'túi',  'bundle', 1.0000, 1.00, FALSE, 3),
((SELECT id FROM unit_categories WHERE code='bundle'), 'bich', 'Bịch', 'bịch', 'bundle', 1.0000, 1.00, FALSE, 4),
((SELECT id FROM unit_categories WHERE code='bundle'), 'khay', 'Khay', 'khay', 'bundle', 1.0000, 1.00, FALSE, 5),

-- Thể tích — cần nhập độ lớn (500 ml, 1.5 lít...)
((SELECT id FROM unit_categories WHERE code='volume'), 'lit',   'Lít',   'l',     'ml',  1000.0000, 0.50, TRUE,  1),
-- Chai/Lon/Thùng — đã có kích thước cố định, không cần nhập
((SELECT id FROM unit_categories WHERE code='volume'), 'chai',  'Chai',  'chai',  'ml',   500.0000, 1.00, FALSE, 2),
((SELECT id FROM unit_categories WHERE code='volume'), 'lon',   'Lon',   'lon',   'ml',   330.0000, 1.00, FALSE, 3),
((SELECT id FROM unit_categories WHERE code='volume'), 'thung', 'Thùng', 'thùng', 'ml', 20000.0000, 1.00, FALSE, 4);

-- Categories
INSERT INTO categories (name, icon_url) VALUES
('Thịt, Cá, Trứng',       'https://res.cloudinary.com/demo/image/upload/v1/icons/meat.png'),
('Rau củ quả',             'https://res.cloudinary.com/demo/image/upload/v1/icons/vegetables.png'),
('Trái cây',               'https://res.cloudinary.com/demo/image/upload/v1/icons/fruits.png'),
('Gạo, Mì, Bột',           'https://res.cloudinary.com/demo/image/upload/v1/icons/grains.png'),
('Gia vị',                 'https://res.cloudinary.com/demo/image/upload/v1/icons/spices.png'),
('Đồ uống',                'https://res.cloudinary.com/demo/image/upload/v1/icons/drinks.png'),
('Sữa & Sản phẩm từ sữa', 'https://res.cloudinary.com/demo/image/upload/v1/icons/dairy.png'),
('Đồ khô',                 'https://res.cloudinary.com/demo/image/upload/v1/icons/dry.png');

-- Users  (password: 123456 — BCrypt hash đã verify)
INSERT INTO users (phone_number, password_hash, role, full_name, address, status) VALUES
('0901234567', '$2b$10$Od2FJqoeLCvFJe4Lw.9YduJB/USp9xt91LbDCooylkJ4l7BP3W4Yu', 'CUSTOMER', 'Nguyễn Văn A',  '123 Nguyễn Huệ, Q1, TP.HCM',   'ACTIVE'),
('0902345678', '$2b$10$Od2FJqoeLCvFJe4Lw.9YduJB/USp9xt91LbDCooylkJ4l7BP3W4Yu', 'STORE',    'Trần Thị B',    '456 Lê Lợi, Q1, TP.HCM',       'ACTIVE'),
('0903456789', '$2b$10$Od2FJqoeLCvFJe4Lw.9YduJB/USp9xt91LbDCooylkJ4l7BP3W4Yu', 'SHIPPER',  'Lê Văn C',      '789 Trần Hưng Đạo, Q5, TP.HCM', 'ACTIVE'),
('0904567890', '$2b$10$Od2FJqoeLCvFJe4Lw.9YduJB/USp9xt91LbDCooylkJ4l7BP3W4Yu', 'ADMIN',    'Quản trị viên', 'HQ Office',                     'ACTIVE'),
('0905678901', '$2b$10$Od2FJqoeLCvFJe4Lw.9YduJB/USp9xt91LbDCooylkJ4l7BP3W4Yu', 'CUSTOMER', 'Phạm Thị D',    '321 Võ Văn Tần, Q3, TP.HCM',    'ACTIVE');

-- Stores
INSERT INTO stores (user_id, store_name, address, is_open) VALUES
(2, 'Tạp hóa Cô Ba', '456 Lê Lợi, Q1, TP.HCM', TRUE);

-- Products
INSERT INTO products (store_id, category_id, name, description, status) VALUES
-- Thịt, Cá, Trứng (cat 1)
(1, 1, 'Thịt ba rọi heo', 'Thịt ba rọi heo tươi ngon, mỡ săn chắc', 'AVAILABLE'),  -- id 1
(1, 1, 'Cá thu',          'Cá thu biển tươi',                         'AVAILABLE'),  -- id 2
(1, 1, 'Trứng gà',        'Trứng gà ta',                              'AVAILABLE'),  -- id 3
(1, 1, 'Thịt bò xào',    'Thịt bò tươi',                             'AVAILABLE'),  -- id 4
-- Rau củ quả (cat 2)
(1, 2, 'Rau muống', 'Rau muống xanh sạch',  'AVAILABLE'),  -- id 5
(1, 2, 'Hành lá',   'Hành lá tươi',          'AVAILABLE'),  -- id 6
(1, 2, 'Cà chua',   'Cà chua Đà Lạt',        'AVAILABLE'),  -- id 7
(1, 2, 'Khoai tây', 'Khoai tây nhập khẩu',   'AVAILABLE'),  -- id 8
-- Trái cây (cat 3)
(1, 3, 'Cam Úc', 'Cam Úc nhập khẩu', 'AVAILABLE'),  -- id 9
(1, 3, 'Táo Mỹ', 'Táo Mỹ nhập khẩu', 'AVAILABLE'),  -- id 10
(1, 3, 'Chuối',  'Chuối Laba',        'AVAILABLE'),  -- id 11
-- Gạo, Mì, Bột (cat 4)
(1, 4, 'Gạo ST25',       'Gạo ST25 thơm ngon', 'AVAILABLE'),  -- id 12
(1, 4, 'Mì gói Hảo Hảo', 'Mì gói ăn liền',     'AVAILABLE'),  -- id 13
-- Gia vị (cat 5)
(1, 5, 'Muối iốt',  'Muối tinh luyện', 'AVAILABLE'),  -- id 14
(1, 5, 'Đường cát', 'Đường cát trắng', 'AVAILABLE'),  -- id 15
-- Đồ uống (cat 6)
(1, 6, 'Coca Cola',    'Nước ngọt Coca Cola', 'AVAILABLE'),  -- id 16
(1, 6, 'Bia Heineken', 'Bia Heineken lon',    'AVAILABLE');  -- id 17

-- =========================================================
-- Product unit mappings (VARIANTS)
-- Khi requires_quantity_input = TRUE:
--   → unit_label tự ghép từ base_quantity + symbol: "500g", "1.5kg"
--   → base_quantity lưu con số người dùng nhập (500, 1.5...)
-- Khi requires_quantity_input = FALSE:
--   → unit_label = tên mô tả: "1 Bó", "Vỉ 10 quả", "Thùng 24 lon"
--   → base_quantity = 1 (hoặc số cố định nếu biết)
-- Columns: product_id, unit_id, unit_label, price, stock_quantity, base_quantity, base_unit, sort_order, is_default, is_active
-- =========================================================
INSERT INTO product_unit_mappings
    (product_id, unit_id, unit_label, price, stock_quantity, base_quantity, base_unit, sort_order, is_default, is_active)
VALUES
-- ── Thịt ba rọi heo (id 1) ──────────────────────────────
-- Đơn vị chuẩn: Gram — 3 size khác nhau, không conflict
(1, (SELECT id FROM units WHERE code='gram'), '300g',    35000.00,  50,  300.0, 'gram', 1, TRUE,  TRUE),
(1, (SELECT id FROM units WHERE code='gram'), '500g',    55000.00,  30,  500.0, 'gram', 2, FALSE, TRUE),
(1, (SELECT id FROM units WHERE code='kg'),   '1kg',    110000.00,  20, 1000.0, 'gram', 3, FALSE, TRUE),

-- ── Cá thu (id 2) ───────────────────────────────────────
(2, (SELECT id FROM units WHERE code='con'), '1 Con',   85000.00,  15,  1.0, 'count', 1, TRUE,  TRUE),

-- ── Trứng gà (id 3) ─────────────────────────────────────
(3, (SELECT id FROM units WHERE code='vi'),  'Vỉ 10 quả', 28000.00, 40, 10.0, 'count', 1, TRUE,  TRUE),
(3, (SELECT id FROM units WHERE code='vi'),  'Vỉ 6 quả',  17000.00, 30,  6.0, 'count', 2, FALSE, TRUE),

-- ── Thịt bò xào (id 4) ──────────────────────────────────
(4, (SELECT id FROM units WHERE code='lang'), '1 Lạng',  18000.00, 50, 100.0, 'gram', 1, TRUE,  TRUE),
(4, (SELECT id FROM units WHERE code='gram'), '400g',    70000.00, 25, 400.0, 'gram', 2, FALSE, TRUE),

-- ── Rau muống (id 5) ────────────────────────────────────
(5, (SELECT id FROM units WHERE code='bo'), '1 Bó',     5000.00, 100, 1.0, 'bundle', 1, TRUE,  TRUE),
(5, (SELECT id FROM units WHERE code='bo'), 'Bó lớn',  10000.00,  40, 1.0, 'bundle', 2, FALSE, TRUE),

-- ── Hành lá (id 6) ──────────────────────────────────────
(6, (SELECT id FROM units WHERE code='bo'), '1 Bó',     3000.00,  80, 1.0, 'bundle', 1, TRUE,  TRUE),

-- ── Cà chua (id 7) ──────────────────────────────────────
(7, (SELECT id FROM units WHERE code='kg'), '1 Kg',    25000.00,  60, 1000.0, 'gram', 1, TRUE,  TRUE),

-- ── Khoai tây (id 8) ────────────────────────────────────
(8, (SELECT id FROM units WHERE code='kg'), '1 Kg',    35000.00,  50, 1000.0, 'gram', 1, TRUE,  TRUE),

-- ── Cam Úc (id 9) ───────────────────────────────────────
(9, (SELECT id FROM units WHERE code='kg'),  '1 Kg',   45000.00, 30, 1000.0, 'gram', 1, TRUE,  TRUE),
(9, (SELECT id FROM units WHERE code='tui'), 'Túi 2kg', 85000.00, 15, 2000.0, 'gram', 2, FALSE, TRUE),

-- ── Táo Mỹ (id 10) ──────────────────────────────────────
(10, (SELECT id FROM units WHERE code='kg'), '1 Kg',   55000.00, 25, 1000.0, 'gram', 1, TRUE,  TRUE),

-- ── Chuối (id 11) ───────────────────────────────────────
(11, (SELECT id FROM units WHERE code='bo'), '1 Nải',  35000.00, 20, 1.0, 'bundle', 1, TRUE,  TRUE),

-- ── Gạo ST25 (id 12) ────────────────────────────────────
-- Cùng unit 'tui', 2 size → không conflict vì bỏ UNIQUE
(12, (SELECT id FROM units WHERE code='tui'), 'Túi 5kg',  125000.00, 40, 5000.0,  'gram', 1, TRUE,  TRUE),
(12, (SELECT id FROM units WHERE code='tui'), 'Túi 10kg', 240000.00, 25, 10000.0, 'gram', 2, FALSE, TRUE),

-- ── Mì gói Hảo Hảo (id 13) ─────────────────────────────
(13, (SELECT id FROM units WHERE code='thung'), 'Thùng 30 gói', 95000.00, 30,  30.0, 'count', 1, TRUE,  TRUE),
(13, (SELECT id FROM units WHERE code='goi'),   '1 Gói',         3500.00, 200,   1.0, 'count', 2, FALSE, TRUE),

-- ── Muối iốt (id 14) ────────────────────────────────────
(14, (SELECT id FROM units WHERE code='bich'), '1 Bịch', 8000.00, 100, 1.0, 'bundle', 1, TRUE,  TRUE),

-- ── Đường cát (id 15) ───────────────────────────────────
(15, (SELECT id FROM units WHERE code='kg'), '1 Kg',    22000.00, 50, 1000.0, 'gram', 1, TRUE,  TRUE),

-- ── Coca Cola (id 16) ───────────────────────────────────
(16, (SELECT id FROM units WHERE code='thung'), 'Thùng 24 lon', 280000.00, 20, 24.0, 'count', 1, TRUE,  TRUE),
(16, (SELECT id FROM units WHERE code='lon'),   '1 Lon',         12000.00, 100, 1.0, 'count', 2, FALSE, TRUE),

-- ── Bia Heineken (id 17) ────────────────────────────────
(17, (SELECT id FROM units WHERE code='thung'), 'Thùng 24 lon', 420000.00, 15, 24.0, 'count', 1, TRUE,  TRUE),
(17, (SELECT id FROM units WHERE code='lon'),   '1 Lon',         18000.00, 80,  1.0, 'count', 2, FALSE, TRUE);

-- =========================================================
-- VIEW
-- =========================================================
CREATE VIEW product_with_units AS
SELECT
    p.id            AS product_id,
    p.name          AS product_name,
    p.description,
    p.image_url,
    p.status,
    c.name          AS category_name,
    s.store_name,
    pum.id          AS variant_id,
    pum.unit_label,
    pum.price,
    pum.stock_quantity,
    pum.base_quantity,
    pum.base_unit,
    pum.sort_order,
    pum.is_default,
    u.id            AS unit_id,
    u.code          AS unit_code,
    u.name          AS unit_name,
    u.symbol        AS unit_symbol,
    u.step_value,
    uc.code         AS unit_category_code,
    uc.name         AS unit_category_name
FROM products p
LEFT JOIN categories          c   ON p.category_id  = c.id
LEFT JOIN stores              s   ON p.store_id      = s.id
LEFT JOIN product_unit_mappings pum ON p.id          = pum.product_id AND pum.is_active = TRUE
LEFT JOIN units               u   ON pum.unit_id     = u.id
LEFT JOIN unit_categories     uc  ON u.category_id   = uc.id
ORDER BY p.id, pum.sort_order;

-- =========================================================
-- TRIGGERS
-- =========================================================
DELIMITER $$

CREATE TRIGGER tr_sync_payment_status_on_insert
AFTER INSERT ON payments FOR EACH ROW
BEGIN
    IF NEW.status != 'PENDING' THEN
        UPDATE orders SET payment_status = NEW.status WHERE id = NEW.order_id;
    END IF;
END$$

CREATE TRIGGER tr_sync_payment_status_on_update
AFTER UPDATE ON payments FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        UPDATE orders SET payment_status = NEW.status WHERE id = NEW.order_id;
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- VERIFY
-- =========================================================
SELECT 'Database setup complete v2.2!' AS status;
SELECT CONCAT('Unit categories : ', COUNT(*)) AS info FROM unit_categories;
SELECT CONCAT('Units           : ', COUNT(*)) AS info FROM units;
SELECT CONCAT('Categories      : ', COUNT(*)) AS info FROM categories;
SELECT CONCAT('Products        : ', COUNT(*)) AS info FROM products;
SELECT CONCAT('Variants        : ', COUNT(*)) AS info FROM product_unit_mappings;