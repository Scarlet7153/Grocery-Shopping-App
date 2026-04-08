package com.grocery.server.order.service;

import com.grocery.server.messaging.dto.OrderAcceptedEvent;
import com.grocery.server.messaging.publisher.RedisMessagePublisher;
import com.grocery.server.order.entity.Order;
import com.grocery.server.order.repository.OrderRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;

/**
 * Service: OrderAcceptanceService
 * Mục đích: Xử lý logic shipper nhận đơn hàng với race condition protection
 * Phase: 7 - Order Acceptance Service
 * 
 * Flow:
 * 1. Shipper gửi request nhận đơn
 * 2. Try acquire distributed lock (Redis SET NX)
 * 3. Nếu lock thành công:
 *    - Double-check order status (còn PENDING không)
 *    - Cập nhật order với shipperId
 *    - Đổi status thành CONFIRMED
 *    - Publish event đến tất cả clients
 * 4. Nếu lock thất bại: Return 409 Conflict
 * 
 * Race Condition Handling:
 * - 2 shipper cùng accept 1 order cùng lúc
 * - Chỉ 1 ngườicó lock sẽ thành công
 * - Ngườicòn lại nhận 409 Conflict
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OrderAcceptanceService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final OrderLockService orderLockService;
    private final RedisMessagePublisher messagePublisher;

    /**
     * Shipper nhận đơn hàng
     * 
     * @param orderId ID đơn hàng
     * @param shipperId ID shipper
     * @return OrderAcceptedResult kết quả nhận đơn
     */
    @Transactional
    public OrderAcceptanceResult acceptOrder(Long orderId, Long shipperId) {
        log.info("Shipper {} attempting to accept order {}", shipperId, orderId);

        // Bước 1: Validate shipper tồn tại và có role SHIPPER
        User shipper = validateShipper(shipperId);

        // Bước 2: Try acquire distributed lock
        OrderLockService.LockToken lockToken = orderLockService.tryLock(orderId);
        
        if (lockToken == null) {
            log.warn("Order {} is already being processed by another shipper", orderId);
            return OrderAcceptanceResult.rejected("Order is being processed by another shipper");
        }

        try {
            // Bước 3: Double-check order status (tránh race condition)
            Order order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Order not found: " + orderId));

            if (order.getStatus() != Order.OrderStatus.PENDING) {
                log.warn("Order {} is no longer available. Current status: {}", 
                        orderId, order.getStatus());
                return OrderAcceptanceResult.rejected(
                        "Order is no longer available. Status: " + order.getStatus());
            }

            // Bước 4: Validate shipper chưa nhận đơn nào khác (optional)
            // TODO: Kiểm tra shipper có đang giao đơn nào không

            // Bước 5: Cập nhật order
            order.setShipper(shipper);
            order.setStatus(Order.OrderStatus.CONFIRMED);
            orderRepository.save(order);

            log.info("Order {} successfully accepted by shipper {}", orderId, shipperId);

            // Bước 6: Publish event
            publishOrderAcceptedEvent(order, shipper);

            return OrderAcceptanceResult.success(order, shipper);

        } catch (Exception e) {
            log.error("Error accepting order {}: {}", orderId, e.getMessage());
            throw e;
        } finally {
            // Bước 7: Release lock (luôn thực hiện)
            orderLockService.unlock(lockToken);
        }
    }

    /**
     * Validate shipper có tồn tại và có role SHIPPER
     */
    private User validateShipper(Long shipperId) {
        User shipper = userRepository.findById(shipperId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Shipper not found: " + shipperId));

        if (shipper.getRole() != User.UserRole.SHIPPER) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, "User is not a shipper");
        }

        return shipper;
    }

    /**
     * Publish OrderAcceptedEvent đến Redis Pub/Sub
     */
    private void publishOrderAcceptedEvent(Order order, User shipper) {
        OrderAcceptedEvent event = OrderAcceptedEvent.builder()
                .orderId(order.getId())
                .customerId(order.getCustomer().getId())
                .storeId(order.getStore().getId())
                .shipperId(shipper.getId())
                .shipperName(shipper.getFullName())
                .shipperPhone(shipper.getPhoneNumber())
                .acceptedAt(LocalDateTime.now())
                .build();

        // Publish đến Redis
        messagePublisher.publishOrderEvent("accepted", order.getId(), event);
        
        // Cũng publish đến general channel
        messagePublisher.publish("order:accepted:" + order.getId(), event);

        log.debug("Published OrderAcceptedEvent for order {}", order.getId());
    }

    /**
     * Kiểm tra xem shipper có thể nhận đơn này không
     */
    public boolean canAcceptOrder(Long orderId, Long shipperId) {
        // Check order tồn tại và status = PENDING
        Order order = orderRepository.findById(orderId).orElse(null);
        if (order == null || order.getStatus() != Order.OrderStatus.PENDING) {
            return false;
        }

        // Check shipper tồn tại và có role SHIPPER
        User shipper = userRepository.findById(shipperId).orElse(null);
        if (shipper == null || shipper.getRole() != User.UserRole.SHIPPER) {
            return false;
        }

        return true;
    }

    // ========== Result DTO ==========

    public static class OrderAcceptanceResult {
        private final boolean success;
        private final String message;
        private final Order order;
        private final User shipper;

        private OrderAcceptanceResult(boolean success, String message, Order order, User shipper) {
            this.success = success;
            this.message = message;
            this.order = order;
            this.shipper = shipper;
        }

        public static OrderAcceptanceResult success(Order order, User shipper) {
            return new OrderAcceptanceResult(true, "Order accepted successfully", order, shipper);
        }

        public static OrderAcceptanceResult rejected(String reason) {
            return new OrderAcceptanceResult(false, reason, null, null);
        }

        public boolean isSuccess() {
            return success;
        }

        public String getMessage() {
            return message;
        }

        public Order getOrder() {
            return order;
        }

        public User getShipper() {
            return shipper;
        }
    }
}