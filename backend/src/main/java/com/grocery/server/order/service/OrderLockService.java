package com.grocery.server.order.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Service: OrderLockService
 * Mục đích: Distributed lock sử dụng Redis SET NX để ngăn race condition khi nhiều shipper cùng nhận đơn
 * Phase: 6 - Distributed Lock
 */
@Service
@Slf4j
public class OrderLockService {

    private final StringRedisTemplate redisTemplate;

    @Autowired
    public OrderLockService(@Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
        if (redisTemplate == null) {
            log.warn("Redis is disabled. OrderLockService will use mock locks (always succeed).");
        }
    }

    private static final String LOCK_PREFIX = "lock:order:";
    private static final long LOCK_TTL_SECONDS = 10; // 10 giây
    private static final long LOCK_TTL_MILLISECONDS = LOCK_TTL_SECONDS * 1000;

    /**
     * Thử acquire lock cho order
     * 
     * @param orderId ID của đơn hàng
     * @return LockToken nếu thành công, null nếu lock đã tồn tại
     */
    public LockToken tryLock(Long orderId) {
        if (redisTemplate == null) {
            log.trace("Redis disabled, returning mock lock for order {}", orderId);
            return new LockToken(orderId, "mock-token-" + UUID.randomUUID());
        }
        String lockKey = LOCK_PREFIX + orderId;
        String lockValue = generateLockValue();

        log.debug("Attempting to acquire lock for order {} with value {}", orderId, lockValue);

        // Sử dụng SET NX với TTL
        Boolean acquired = redisTemplate.opsForValue()
                .setIfAbsent(lockKey, lockValue, LOCK_TTL_MILLISECONDS, TimeUnit.MILLISECONDS);

        if (Boolean.TRUE.equals(acquired)) {
            log.info("Lock acquired for order {} with token {}", orderId, lockValue);
            return new LockToken(orderId, lockValue);
        } else {
            log.warn("Failed to acquire lock for order {} - already locked", orderId);
            return null;
        }
    }

    /**
     * Thử acquire lock cho order với custom timeout
     * 
     * @param orderId ID của đơn hàng
     * @param timeoutMs Thờigian timeout tính bằng milliseconds
     * @return LockToken nếu thành công, null nếu lock đã tồn tại
     */
    public LockToken tryLock(Long orderId, long timeoutMs) {
        if (redisTemplate == null) {
            log.trace("Redis disabled, returning mock lock for order {}", orderId);
            return new LockToken(orderId, "mock-token-" + UUID.randomUUID());
        }
        String lockKey = LOCK_PREFIX + orderId;
        String lockValue = generateLockValue();

        log.debug("Attempting to acquire lock for order {} with timeout {}ms", orderId, timeoutMs);

        Boolean acquired = redisTemplate.opsForValue()
                .setIfAbsent(lockKey, lockValue, timeoutMs, TimeUnit.MILLISECONDS);

        if (Boolean.TRUE.equals(acquired)) {
            log.info("Lock acquired for order {} with token {}", orderId, lockValue);
            return new LockToken(orderId, lockValue);
        } else {
            log.warn("Failed to acquire lock for order {} - already locked", orderId);
            return null;
        }
    }

    /**
     * Release lock cho order
     * Chỉ xóa lock nếu value khớp (tránh xóa nhầm lock của ngườikhác)
     * 
     * @param orderId ID của đơn hàng
     * @param lockValue Giá trị lock token
     * @return true nếu unlock thành công
     */
    public boolean unlock(Long orderId, String lockValue) {
        if (redisTemplate == null) {
            log.trace("Redis disabled, skipping unlock for order {}", orderId);
            return true;
        }
        String lockKey = LOCK_PREFIX + orderId;

        // Kiểm tra xem lock có tồn tại và value có khớp không
        String currentValue = redisTemplate.opsForValue().get(lockKey);

        if (currentValue == null) {
            log.warn("Lock for order {} does not exist or already expired", orderId);
            return true; // Lock đã được release hoặc expire
        }

        if (!currentValue.equals(lockValue)) {
            log.error("Cannot unlock order {} - lock value mismatch. Expected: {}, Actual: {}", 
                    orderId, lockValue, currentValue);
            return false; // Không phải lock của mình, không được xóa
        }

        // Xóa lock
        Boolean deleted = redisTemplate.delete(lockKey);
        if (Boolean.TRUE.equals(deleted)) {
            log.info("Lock released for order {}", orderId);
            return true;
        } else {
            log.warn("Failed to release lock for order {}", orderId);
            return false;
        }
    }

    /**
     * Release lock sử dụng LockToken
     * 
     * @param token LockToken từ tryLock
     * @return true nếu unlock thành công
     */
    public boolean unlock(LockToken token) {
        if (token == null) {
            return false;
        }
        return unlock(token.getOrderId(), token.getLockValue());
    }

    /**
     * Kiểm tra xem order có đang bị lock không
     * 
     * @param orderId ID của đơn hàng
     * @return true nếu đang bị lock
     */
    public boolean isLocked(Long orderId) {
        if (redisTemplate == null) return false;
        String lockKey = LOCK_PREFIX + orderId;
        String currentValue = redisTemplate.opsForValue().get(lockKey);
        return currentValue != null;
    }

    /**
     * Lấy thông tin lock hiện tại
     * 
     * @param orderId ID của đơn hàng
     * @return LockValue nếu tồn tại, null nếu không có lock
     */
    public String getLockValue(Long orderId) {
        if (redisTemplate == null) return null;
        String lockKey = LOCK_PREFIX + orderId;
        return redisTemplate.opsForValue().get(lockKey);
    }

    /**
     * Gia hạn thờigian lock
     * 
     * @param token LockToken
     * @param additionalTimeMs Thờigian gia hạn thêm (milliseconds)
     * @return true nếu gia hạn thành công
     */
    public boolean extendLock(LockToken token, long additionalTimeMs) {
        if (token == null) {
            return false;
        }
        if (redisTemplate == null) return true;

        String lockKey = LOCK_PREFIX + token.getOrderId();
        String currentValue = redisTemplate.opsForValue().get(lockKey);

        if (currentValue == null || !currentValue.equals(token.getLockValue())) {
            log.warn("Cannot extend lock for order {} - lock not found or value mismatch", 
                    token.getOrderId());
            return false;
        }

        // Gia hạn TTL
        Boolean extended = redisTemplate.expire(lockKey, additionalTimeMs, TimeUnit.MILLISECONDS);
        if (Boolean.TRUE.equals(extended)) {
            log.info("Lock extended for order {} by {}ms", token.getOrderId(), additionalTimeMs);
            return true;
        } else {
            log.warn("Failed to extend lock for order {}", token.getOrderId());
            return false;
        }
    }

    /**
     * Generate unique lock value
     */
    private String generateLockValue() {
        return UUID.randomUUID().toString();
    }

    /**
     * Lock Token - Chứa thông tin lock để verify khi unlock
     */
    public static class LockToken {
        private final Long orderId;
        private final String lockValue;
        private final long createdAt;

        public LockToken(Long orderId, String lockValue) {
            this.orderId = orderId;
            this.lockValue = lockValue;
            this.createdAt = System.currentTimeMillis();
        }

        public Long getOrderId() {
            return orderId;
        }

        public String getLockValue() {
            return lockValue;
        }

        public long getCreatedAt() {
            return createdAt;
        }

        /**
         * Kiểm tra lock còn hiệu lực không
         */
        public boolean isValid() {
            long age = System.currentTimeMillis() - createdAt;
            return age < LOCK_TTL_MILLISECONDS;
        }

        @Override
        public String toString() {
            return "LockToken{" +
                    "orderId=" + orderId +
                    ", lockValue='" + lockValue + '\'' +
                    ", createdAt=" + createdAt +
                    '}';
        }
    }
}