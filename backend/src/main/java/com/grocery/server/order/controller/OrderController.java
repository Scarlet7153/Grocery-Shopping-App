package com.grocery.server.order.controller;

import com.grocery.server.order.dto.request.CreateOrderRequest;
import com.grocery.server.order.dto.request.UpdateOrderStatusRequest;
import com.grocery.server.order.dto.response.OrderResponse;
import com.grocery.server.order.dto.response.OrderStatisticsResponse;
import com.grocery.server.order.entity.Order;
import com.grocery.server.order.service.OrderService;
import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller: OrderController
 * Endpoint: /api/orders
 * Mô tả: Quản lý đơn hàng (Order Management)
 */
@RestController
@RequestMapping("/orders")
@RequiredArgsConstructor
@Slf4j
public class OrderController {

    private final OrderService orderService;
    private final UserRepository userRepository;

    /**
     * Tạo đơn hàng mới
     * POST /api/orders
     * Role: CUSTOMER
     */
    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<OrderResponse>> createOrder(
            @Valid @RequestBody CreateOrderRequest request,
            Authentication authentication) {

        Long customerId = getUserIdFromAuthentication(authentication);
        OrderResponse response = orderService.createOrder(request, customerId);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo đơn hàng thành công", response));
    }

    /**
     * Lấy thông tin đơn hàng theo ID
     * GET /api/orders/{id}
     * Role: Tất cả user đã đăng nhập
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrderById(@PathVariable Long id) {
        OrderResponse response = orderService.getOrderById(id);
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin đơn hàng thành công", response));
    }

    /**
     * Lấy tất cả đơn hàng của khách hàng hiện tại
     * GET /api/orders/my-orders
     * Role: CUSTOMER
     */
    @GetMapping("/my-orders")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getMyOrders(Authentication authentication) {
        Long customerId = getUserIdFromAuthentication(authentication);
        List<OrderResponse> orders = orderService.getOrdersByCustomer(customerId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn hàng thành công", orders));
    }

    /**
     * Lấy đơn hàng của khách hàng - CÓ PHÂN TRANG
     * GET /api/orders/my-orders/paged?page=0&size=10
     * Role: CUSTOMER
     */
    @GetMapping("/my-orders/paged")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<OrderResponse>>> getMyOrdersPaged(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {
        Long customerId = getUserIdFromAuthentication(authentication);
        org.springframework.data.domain.Page<OrderResponse> orders = orderService.getOrdersByCustomerPaginated(customerId, page, size);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn hàng thành công", orders));
    }

    /**
     * Lấy đơn hàng của một khách hàng cụ thể (Admin only)
     * GET /api/orders/user/{userId}
     * Role: ADMIN
     */
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getOrdersByUserId(@PathVariable Long userId) {
        log.info("GET /api/orders/user/{} - Get orders by user (Admin)", userId);
        List<OrderResponse> orders = orderService.getOrdersByCustomer(userId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn hàng của user thành công", orders));
    }

    /**
     * Lấy tất cả đơn hàng của cửa hàng hiện tại
     * GET /api/orders/my-store-orders
     * Role: STORE (chỉ lấy đơn của cửa hàng mình)
     */
    @GetMapping("/my-store-orders")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getMyStoreOrders(Authentication authentication) {
        Long userId = getUserIdFromAuthentication(authentication);
        List<OrderResponse> orders = orderService.getOrdersByStoreOwner(userId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn hàng cửa hàng thành công", orders));
    }

    /**
     * Lấy đơn hàng của cửa hàng - CÓ PHÂN TRANG
     * GET /api/orders/my-store-orders/paged?page=0&size=10
     * Role: STORE
     */
    @GetMapping("/my-store-orders/paged")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<OrderResponse>>> getMyStoreOrdersPaged(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {
        Long userId = getUserIdFromAuthentication(authentication);
        org.springframework.data.domain.Page<OrderResponse> orders = orderService.getOrdersByStoreOwnerPaginated(userId, page, size);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn hàng cửa hàng thành công", orders));
    }

    /**
     * Lấy tất cả đơn hàng (dành cho admin)
     * GET /api/orders/all
     * Role: ADMIN
     */
    @GetMapping("/all")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<OrderResponse>>> getAllOrdersForAdmin(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir,
            @RequestParam(required = false) Long storeId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to
    ) {
        Order.OrderStatus statusEnum = null;
        if (status != null && !status.isBlank()) {
            try {
                statusEnum = Order.OrderStatus.valueOf(status.toUpperCase());
            } catch (IllegalArgumentException ex) {
                throw new com.grocery.server.shared.exception.BadRequestException("Trạng thái không hợp lệ: " + status);
            }
        }

        java.time.LocalDateTime fromDt = parseDateTime(from);
        java.time.LocalDateTime toDt = parseDateTime(to);

        org.springframework.data.domain.Page<OrderResponse> result = orderService.getAllOrdersPaginated(page, size, sortBy, sortDir, storeId, statusEnum, fromDt, toDt);
        return ResponseEntity.ok(ApiResponse.success("Lấy tất cả đơn hàng thành công", result));
    }

    /**
     * Lấy thống kê đơn hàng cho Dashboard Admin
     * GET /api/orders/statistics
     * Role: ADMIN
     */
    @GetMapping("/statistics")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<OrderStatisticsResponse>> getOrderStatistics() {
        OrderStatisticsResponse stats = orderService.getOrderStatistics();
        return ResponseEntity.ok(ApiResponse.success("Lấy thống kê đơn hàng thành công", stats));
    }

    private java.time.LocalDateTime parseDateTime(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            return java.time.LocalDateTime.parse(s);
        } catch (java.time.format.DateTimeParseException ex) {
            try {
                return java.time.LocalDate.parse(s).atStartOfDay();
            } catch (java.time.format.DateTimeParseException ex2) {
                throw new com.grocery.server.shared.exception.BadRequestException("Định dạng ngày không hợp lệ: " + s + ". Dùng ISO date hoặc datetime.");
            }
        }
    }

    /**
     * Lấy tất cả đơn hàng của tài xế hiện tại
     * GET /api/orders/my-deliveries
     * Role: SHIPPER
     */
    @GetMapping("/my-deliveries")
    @PreAuthorize("hasRole('SHIPPER')")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getMyDeliveries(Authentication authentication) {
        Long shipperId = getUserIdFromAuthentication(authentication);
        List<OrderResponse> orders = orderService.getOrdersByShipper(shipperId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn giao hàng thành công", orders));
    }

    /**
     * Lấy đơn giao hàng của tài xế - CÓ PHÂN TRANG
     * GET /api/orders/my-deliveries/paged?page=0&size=10
     * Role: SHIPPER
     */
    @GetMapping("/my-deliveries/paged")
    @PreAuthorize("hasRole('SHIPPER')")
    public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<OrderResponse>>> getMyDeliveriesPaged(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {
        Long shipperId = getUserIdFromAuthentication(authentication);
        org.springframework.data.domain.Page<OrderResponse> orders = orderService.getOrdersByShipperPaginated(shipperId, page, size);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn giao hàng thành công", orders));
    }

    /**
     * Lấy danh sách đơn hàng có thể nhận (cho tài xế)
     * GET /api/orders/available
     * Role: SHIPPER
     */
    @GetMapping("/available")
    @PreAuthorize("hasRole('SHIPPER')")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getAvailableOrders() {
        List<OrderResponse> orders = orderService.getAvailableOrders();
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn hàng có thể nhận thành công", orders));
    }

    /**
     * Lấy đơn hàng có thể nhận - CÓ PHÂN TRANG
     * GET /api/orders/available/paged?page=0&size=10
     * Role: SHIPPER
     */
    @GetMapping("/available/paged")
    @PreAuthorize("hasRole('SHIPPER')")
    public ResponseEntity<ApiResponse<org.springframework.data.domain.Page<OrderResponse>>> getAvailableOrdersPaged(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        org.springframework.data.domain.Page<OrderResponse> orders = orderService.getAvailableOrdersPaginated(page, size);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn hàng có thể nhận thành công", orders));
    }

    /**
     * Cập nhật trạng thái đơn hàng
     * PATCH /api/orders/{id}/status
     * Role: CUSTOMER, STORE, SHIPPER (tùy trạng thái)
     */
    @PatchMapping("/{id}/status")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<OrderResponse>> updateOrderStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateOrderStatusRequest request,
            Authentication authentication) {

        Long userId = getUserIdFromAuthentication(authentication);
        OrderResponse response = orderService.updateOrderStatus(id, request, userId);

        return ResponseEntity.ok(ApiResponse.success("Cập nhật trạng thái đơn hàng thành công", response));
    }

    /**
     * Tài xế nhận đơn
     * POST /api/orders/{id}/assign-shipper
     * Role: SHIPPER
     */
    @PostMapping("/{id}/assign-shipper")
    @PreAuthorize("hasRole('SHIPPER')")
    public ResponseEntity<ApiResponse<OrderResponse>> assignShipper(
            @PathVariable Long id,
            Authentication authentication) {

        Long shipperId = getUserIdFromAuthentication(authentication);
        OrderResponse response = orderService.assignShipper(id, shipperId);

        return ResponseEntity.ok(ApiResponse.success("Nhận đơn hàng thành công", response));
    }

    /**
     * Helper method: Lấy userId từ Authentication
     */
    private Long getUserIdFromAuthentication(Authentication authentication) {
        String phoneNumber = authentication.getName();
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UnauthorizedException("User không tồn tại"));
        return user.getId();
    }
}
