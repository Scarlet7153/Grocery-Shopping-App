-- Migration: add orders.payment_status and add VNPAY enum to payments.payment_method
ALTER TABLE orders
  ADD COLUMN payment_status ENUM('PENDING','SUCCESS','FAILED') NOT NULL DEFAULT 'PENDING' AFTER created_at;

-- If payments.payment_method is ENUM('COD','MOMO'), modify to add VNPAY
-- WARNING: backup your DB before running this migration
ALTER TABLE payments
  MODIFY COLUMN payment_method ENUM('COD','MOMO','VNPAY') NOT NULL;
