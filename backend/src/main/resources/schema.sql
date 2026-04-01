-- =========================================================
-- GROCERY SHOPPING APP - DATABASE SCHEMA
-- =========================================================
-- Database: grocery_final_db
-- Version: 1.0
-- Created: January 2026
-- =========================================================

CREATE DATABASE IF NOT EXISTS grocery_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE grocery_db;

-- =========================================================
-- 1. Table: users (Bảng Người dùng)
-- =========================================================
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(15) UNIQUE NOT NULL COMMENT 'Số điện thoại đăng nhập',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Mật khẩu đã mã hóa BCrypt',
    role ENUM('CUSTOMER', 'SHIPPER', 'STORE', 'ADMIN') NOT NULL COMMENT 'Vai trò tài khoản',
    status ENUM('ACTIVE', 'BANNED') DEFAULT 'ACTIVE' COMMENT 'Trạng thái tài khoản',
    full_name VARCHAR(100) COMMENT 'Họ và tên',
    avatar_url VARCHAR(255) COMMENT 'Đường dẫn ảnh đại diện',
    address VARCHAR(255) COMMENT 'Địa chỉ cá nhân',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number),
    INDEX idx_role (role),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng quản lý người dùng (Khách, Shipper, Cửa hàng, Admin)';

-- =========================================================
-- 2. Table: stores (Bảng Cửa hàng)
-- =========================================================
CREATE TABLE stores (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT 'Chủ cửa hàng (FK users.id)',
    store_name VARCHAR(100) NOT NULL COMMENT 'Tên hiển thị cửa hàng',
    address VARCHAR(255) NOT NULL COMMENT 'Địa chỉ thực tế',
    is_open BOOLEAN DEFAULT TRUE COMMENT 'Trạng thái mở cửa (1=Mở, 0=Đóng)',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_open (is_open)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng cửa hàng';

-- =========================================================
-- 3. Table: categories (Bảng Danh mục)
-- =========================================================
CREATE TABLE categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT 'Tên danh mục (VD: Thịt cá, Rau củ)',
    icon_url VARCHAR(255) COMMENT 'Hình ảnh biểu tượng danh mục',
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng danh mục sản phẩm';

-- =========================================================
-- 4. Table: products (Bảng Thông tin chung Sản phẩm)
-- =========================================================
CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    store_id BIGINT NOT NULL COMMENT 'Thuộc cửa hàng nào',
    category_id BIGINT COMMENT 'Thuộc danh mục nào',
    name VARCHAR(255) NOT NULL COMMENT 'Tên sản phẩm',
    image_url VARCHAR(255) COMMENT 'Hình ảnh sản phẩm',
    description TEXT COMMENT 'Mô tả chi tiết',
    status ENUM('AVAILABLE', 'OUT_OF_STOCK', 'HIDDEN') DEFAULT 'AVAILABLE' COMMENT 'Tình trạng bán',
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_store_id (store_id),
    INDEX idx_category_id (category_id),
    INDEX idx_status (status),
    FULLTEXT INDEX ft_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng thông tin chung sản phẩm (Giá nằm ở product_units)';

-- =========================================================
-- 5. Table: product_units (Bảng Đơn vị & Giá)
-- =========================================================
CREATE TABLE product_units (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL COMMENT 'Thuộc sản phẩm nào',
    unit_name VARCHAR(50) NOT NULL COMMENT 'Tên đơn vị (VD: Gói 300g, 1 Bó, Khay 1kg)',
    price DECIMAL(10, 2) NOT NULL COMMENT 'Giá bán (VNĐ)',
    stock_quantity INT NOT NULL DEFAULT 0 COMMENT 'Số lượng còn trong kho',
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng đơn vị & giá bán (1 sản phẩm nhiều đơn vị)';

-- =========================================================
-- 6. Table: orders (Bảng Đơn hàng)
-- =========================================================
CREATE TABLE orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL COMMENT 'Khách đặt hàng',
    store_id BIGINT NOT NULL COMMENT 'Cửa hàng bán',
    shipper_id BIGINT DEFAULT NULL COMMENT 'Tài xế giao (NULL khi mới đặt)',
    status ENUM('PENDING', 'CONFIRMED', 'PICKING_UP', 'DELIVERING', 'DELIVERED', 'CANCELLED') 
        DEFAULT 'PENDING' COMMENT 'Tình trạng đơn hàng',
    total_amount DECIMAL(10, 2) NOT NULL COMMENT 'Tổng tiền hàng',
    shipping_fee DECIMAL(10, 2) NOT NULL COMMENT 'Phí vận chuyển',
    delivery_address VARCHAR(255) NOT NULL COMMENT 'Địa chỉ giao hàng',
    pod_image_url VARCHAR(255) DEFAULT NULL COMMENT 'Ảnh bằng chứng giao hàng',
    cancel_reason VARCHAR(255) DEFAULT NULL COMMENT 'Lý do hủy đơn',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(id),
    FOREIGN KEY (store_id) REFERENCES stores(id),
    FOREIGN KEY (shipper_id) REFERENCES users(id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_store_id (store_id),
    INDEX idx_shipper_id (shipper_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng đơn hàng';

-- =========================================================
-- 7. Table: order_items (Bảng Chi tiết đơn hàng)
-- =========================================================
CREATE TABLE order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT 'Thuộc đơn hàng nào',
    product_unit_id BIGINT NOT NULL COMMENT 'Mua đơn vị sản phẩm nào',
    quantity INT NOT NULL COMMENT 'Số lượng mua',
    unit_price DECIMAL(10, 2) NOT NULL COMMENT 'Đơn giá tại thời điểm mua',
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_unit_id) REFERENCES product_units(id),
    INDEX idx_order_id (order_id),
    INDEX idx_product_unit_id (product_unit_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng chi tiết đơn hàng';

-- =========================================================
-- 8. Table: payments (Bảng Lịch sử Thanh toán)
-- =========================================================
CREATE TABLE payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT 'Thuộc đơn hàng nào',
    payment_method ENUM('COD', 'MOMO') NOT NULL COMMENT 'Phương thức thanh toán',
    amount DECIMAL(10, 2) NOT NULL COMMENT 'Số tiền giao dịch',
    transaction_code VARCHAR(100) DEFAULT NULL COMMENT 'Mã giao dịch Momo',
    status ENUM('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED') DEFAULT 'PENDING' COMMENT 'Trạng thái giao dịch',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    INDEX idx_order_id (order_id),
    INDEX idx_payment_method (payment_method),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng lịch sử thanh toán';

-- =========================================================
-- 9. Table: reviews (Bảng Đánh giá)
-- =========================================================
CREATE TABLE reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT 'Đánh giá dựa trên đơn hàng nào',
    reviewer_id BIGINT NOT NULL COMMENT 'Khách hàng viết đánh giá',
    store_id BIGINT NOT NULL COMMENT 'Cửa hàng được đánh giá',
    rating TINYINT CHECK (rating BETWEEN 1 AND 5) COMMENT 'Điểm từ 1-5 sao',
    comment TEXT COMMENT 'Nội dung bình luận',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(id),
    FOREIGN KEY (store_id) REFERENCES stores(id),
    INDEX idx_order_id (order_id),
    INDEX idx_reviewer_id (reviewer_id),
    INDEX idx_store_id (store_id),
    INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bảng đánh giá cửa hàng';

-- =========================================================
-- INSERT SAMPLE DATA
-- =========================================================

-- Thêm danh mục
INSERT INTO categories (name, icon_url) VALUES
('Thịt, Cá, Trứng', 'https://example.com/icons/meat.png'),
('Rau củ quả', 'https://example.com/icons/vegetables.png'),
('Trái cây', 'https://example.com/icons/fruits.png'),
('Gạo, Mì, Bột', 'https://example.com/icons/grains.png'),
('Gia vị', 'https://example.com/icons/spices.png'),
('Đồ uống', 'https://example.com/icons/drinks.png');

-- Thêm users
INSERT INTO users (phone_number, password_hash, role, full_name, address) VALUES
-- Password: 123456 (BCrypt hash)
('0901234567', '$2a$10$YourBCryptHashHere', 'CUSTOMER', 'Nguyễn Văn A', '123 Nguyễn Huệ, Q1, TP.HCM'),
('0902345678', '$2a$10$YourBCryptHashHere', 'STORE', 'Trần Thị B', '456 Lê Lợi, Q1, TP.HCM'),
('0903456789', '$2a$10$YourBCryptHashHere', 'SHIPPER', 'Lê Văn C', '789 Trần Hưng Đạo, Q5, TP.HCM'),
('0904567890', '$2a$10$YourBCryptHashHere', 'ADMIN', 'Admin', 'HQ Office');

-- Thêm cửa hàng
INSERT INTO stores (user_id, store_name, address, is_open) VALUES
(2, 'Tạp hóa Cô Ba', '456 Lê Lợi, Q1, TP.HCM', TRUE);

-- Thêm sản phẩm
INSERT INTO products (store_id, category_id, name, description, status) VALUES
(1, 1, 'Thịt ba rọi heo', 'Thịt ba rọi heo tươi ngon', 'AVAILABLE'),
(1, 2, 'Rau muống', 'Rau muống xanh sạch', 'AVAILABLE'),
(1, 3, 'Cam Úc', 'Cam Úc nhập khẩu', 'AVAILABLE'),
(1, 4, 'Gạo ST25', 'Gạo ST25 thơm ngon', 'AVAILABLE');

-- Thêm đơn vị bán
INSERT INTO product_units (product_id, unit_name, price, stock_quantity) VALUES
-- Thịt ba rọi
(1, 'Gói 300g', 35000.00, 50),
(1, 'Khay 1kg', 110000.00, 20),
-- Rau muống
(2, '1 Bó', 5000.00, 100),
-- Cam Úc
(3, '1kg', 45000.00, 30),
(3, 'Túi 2kg', 85000.00, 15),
-- Gạo ST25
(4, 'Túi 5kg', 125000.00, 40),
(4, 'Túi 10kg', 240000.00, 25);

-- =========================================================
-- END OF SCHEMA
-- =========================================================