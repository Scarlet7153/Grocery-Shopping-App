package com.grocery.server.order.service;

import com.grocery.server.messaging.dto.OrderAcceptedEvent;
import com.grocery.server.messaging.dto.OrderCreatedEvent;
import com.grocery.server.messaging.dto.OrderStatusChangedEvent;
import com.grocery.server.messaging.publisher.RedisMessagePublisher;
import com.grocery.server.order.dto.request.CreateOrderRequest;
import com.grocery.server.order.dto.request.UpdateOrderStatusRequest;
import com.grocery.server.order.dto.response.OrderItemResponse;
import com.grocery.server.order.dto.response.OrderResponse;
import com.grocery.server.order.entity.Order;
import com.grocery.server.order.entity.Order.OrderStatus;
import com.grocery.server.order.entity.OrderItem;
import com.grocery.server.order.repository.OrderRepository;
import com.grocery.server.product.entity.ProductUnit;
import com.grocery.server.product.repository.ProductRepository;
import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service: OrderService
 * Mô tả: Xử lý business logic cho Order Module
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final StoreRepository storeRepository;
    private final ProductRepository productRepository;
    private final RedisMessagePublisher messagePublisher;

    // Phí ship cố định (VNĐ) - Có thể cấu hình trong application.properties sau
    private static final BigDecimal SHIPPING_FEE = new BigDecimal("15000.00");

    /**
     * Tạo đơn hàng mới
     * 
     * @param request    Thông tin đơn hàng
     * @param customerId ID khách hàng
     * @return Thông tin đơn hàng vừa tạo
     */
    @Transactional
    public OrderResponse createOrder(CreateOrderRequest request, Long customerId) {
        log.info("Khách hàng {} đang tạo đơn hàng từ cửa hàng {}", customerId, request.getStoreId());

        // 1. Validate customer
        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khách hàng"));

        if (!customer.getRole().equals(User.UserRole.CUSTOMER)) {
            throw new BadRequestException("Chỉ khách hàng mới có thể đặt hàng");
        }

        // 2. Validate store
        Store store = storeRepository.findById(request.getStoreId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy cửa hàng"));

        if (!store.getIsOpen()) {
            throw new BadRequestException("Cửa hàng hiện không hoạt động");
        }

        // 3. Xử lý các sản phẩm trong đơn
        List<OrderItem> orderItems = new ArrayList<>();
        BigDecimal totalAmount = BigDecimal.ZERO;

        Order order = Order.builder()
                .customer(customer)
                .store(store)
                .status(OrderStatus.PENDING)
                .deliveryAddress(request.getDeliveryAddress())
                .shippingFee(SHIPPING_FEE)
                .build();

        for (var itemRequest : request.getItems()) {
            // Validate ProductUnit
            ProductUnit productUnit = productRepository.findProductUnitById(itemRequest.getProductUnitId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Không tìm thấy đơn vị sản phẩm ID: " + itemRequest.getProductUnitId()));

            // Kiểm tra sản phẩm có thuộc cửa hàng này không
            if (!productUnit.getProduct().getStore().getId().equals(request.getStoreId())) {
                throw new BadRequestException(
                        "Sản phẩm '" + productUnit.getProduct().getName() + "' không thuộc cửa hàng này");
            }

            // Kiểm tra tồn kho
            if (productUnit.getStockQuantity() < itemRequest.getQuantity()) {
                throw new BadRequestException(
                        "Sản phẩm '" + productUnit.getProduct().getName() + " - " + productUnit.getUnitName() +
                                "' chỉ còn " + productUnit.getStockQuantity() + " (yêu cầu: "
                                + itemRequest.getQuantity() + ")");
            }

            // Tạo OrderItem
            OrderItem orderItem = OrderItem.builder()
                    .order(order)
                    .productUnit(productUnit)
                    .quantity(itemRequest.getQuantity())
                    .unitPrice(productUnit.getPrice())
                    .build();

            orderItems.add(orderItem);
            totalAmount = totalAmount.add(orderItem.getSubtotal());

            // Trừ tồn kho
            productUnit.setStockQuantity(productUnit.getStockQuantity() - itemRequest.getQuantity());
            log.info("Trừ {} sản phẩm '{}', còn lại: {}",
                    itemRequest.getQuantity(),
                    productUnit.getProduct().getName(),
                    productUnit.getStockQuantity());
        }

        order.setTotalAmount(totalAmount);
        order.setOrderItems(orderItems);

        // Lưu đơn hàng
        Order savedOrder = orderRepository.save(order);
        log.info("Đã tạo đơn hàng #{} với tổng tiền: {} VNĐ", savedOrder.getId(), totalAmount);
        publishOrderCreatedEvent(savedOrder);

        return mapToOrderResponse(savedOrder);
    }

    /**
     * Lấy đơn hàng theo ID
     * 
     * @param orderId ID đơn hàng
     * @return Thông tin đơn hàng
     */
    public OrderResponse getOrderById(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn hàng"));
        return mapToOrderResponse(order);
    }

    /**
     * Lấy tất cả đơn hàng của khách hàng
     * 
     * @param customerId ID khách hàng
     * @return Danh sách đơn hàng
     */
    public List<OrderResponse> getOrdersByCustomer(Long customerId) {
        List<Order> orders = orderRepository.findByCustomerId(customerId);
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy tất cả đơn hàng của cửa hàng
     * 
     * @param storeId ID cửa hàng
     * @return Danh sách đơn hàng
     */
    public List<OrderResponse> getOrdersByStore(Long storeId) {
        List<Order> orders = orderRepository.findByStoreId(storeId);
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy tất cả đơn hàng của cửa hàng thuộc store owner hiện tại
     * 
     * @param userId ID của store owner
     * @return Danh sách đơn hàng
     */
    public List<OrderResponse> getOrdersByStoreOwner(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy user"));

        if (!user.getRole().equals(User.UserRole.STORE)) {
            throw new BadRequestException("Chỉ cửa hàng mới có thể xem đơn hàng của mình");
        }

        Store store = user.getStore();
        if (store == null) {
            throw new ResourceNotFoundException("User này chưa có cửa hàng");
        }

        List<Order> orders = orderRepository.findByStoreId(store.getId());
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy tất cả đơn hàng của tài xế
     * 
     * @param shipperId ID tài xế
     * @return Danh sách đơn hàng
     */
    public List<OrderResponse> getOrdersByShipper(Long shipperId) {
        List<Order> orders = orderRepository.findByShipperId(shipperId);
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy danh sách đơn hàng có thể nhận (cho tài xế)
     * 
     * @return Danh sách đơn hàng đang chờ tài xế
     */
    public List<OrderResponse> getAvailableOrders() {
        List<Order> orders = orderRepository.findAvailableOrdersForShippers();
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Cập nhật trạng thái đơn hàng
     * 
     * @param orderId ID đơn hàng
     * @param request Thông tin cập nhật
     * @param userId  ID người thực hiện
     * @return Thông tin đơn hàng sau khi cập nhật
     */
    @Transactional
    public OrderResponse updateOrderStatus(Long orderId, UpdateOrderStatusRequest request, Long userId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn hàng"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        // Validate state transition
        validateStatusTransition(order, request.getNewStatus(), user);

        // Validate required fields
        if (request.getNewStatus() == OrderStatus.CANCELLED &&
                (request.getCancelReason() == null || request.getCancelReason().isBlank())) {
            throw new BadRequestException("Lý do hủy đơn không được để trống");
        }

        if (request.getNewStatus() == OrderStatus.DELIVERED &&
                (request.getPodImageUrl() == null || request.getPodImageUrl().isBlank())) {
            throw new BadRequestException("Ảnh chứng minh giao hàng không được để trống");
        }

        // Cập nhật trạng thái
        OrderStatus oldStatus = order.getStatus();
        order.setStatus(request.getNewStatus());

        if (request.getCancelReason() != null) {
            order.setCancelReason(request.getCancelReason());
        }

        if (request.getPodImageUrl() != null) {
            order.setPodImageUrl(request.getPodImageUrl());
        }

        orderRepository.save(order);
        log.info("Đơn hàng #{} đã chuyển từ {} sang {}", orderId, oldStatus, request.getNewStatus());
        publishOrderStatusChangedEvent(order, oldStatus, request.getNewStatus(), request.getCancelReason());

        return mapToOrderResponse(order);
    }

    /**
     * Tài xế nhận đơn
     * 
     * @param orderId   ID đơn hàng
     * @param shipperId ID tài xế
     * @return Thông tin đơn hàng
     */
    @Transactional
    public OrderResponse assignShipper(Long orderId, Long shipperId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn hàng"));

        if (order.getStatus() != OrderStatus.CONFIRMED) {
            throw new BadRequestException("Chỉ có thể nhận đơn hàng đã được xác nhận");
        }

        if (order.getShipper() != null) {
            throw new BadRequestException("Đơn hàng đã có tài xế nhận");
        }

        User shipper = userRepository.findById(shipperId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài xế"));

        if (!shipper.getRole().equals(User.UserRole.SHIPPER)) {
            throw new BadRequestException("Chỉ tài xế mới có thể nhận đơn");
        }

        order.setShipper(shipper);
        order.setStatus(OrderStatus.PICKING_UP);

        orderRepository.save(order);
        log.info("Tài xế {} đã nhận đơn hàng #{}", shipper.getFullName(), orderId);
        publishOrderAcceptedEvent(order, shipper);
        publishOrderStatusChangedEvent(order, OrderStatus.CONFIRMED, OrderStatus.PICKING_UP, null);

        return mapToOrderResponse(order);
    }

        private void publishOrderCreatedEvent(Order order) {
        OrderCreatedEvent event = OrderCreatedEvent.builder()
            .eventType("ORDER_CREATED")
            .timestamp(System.currentTimeMillis())
            .orderId(order.getId())
            .customerId(order.getCustomer().getId())
            .storeId(order.getStore().getId())
            .storeName(order.getStore().getStoreName())
            .totalAmount(order.getTotalAmount())
            .shippingFee(order.getShippingFee())
            .deliveryAddress(order.getDeliveryAddress())
            .deliveryLat(null)
            .deliveryLng(null)
            .createdAt(order.getCreatedAt())
            .expiresAt(order.getCreatedAt() != null
                ? order.getCreatedAt().plusMinutes(15)
                : LocalDateTime.now().plusMinutes(15))
            .build();

        messagePublisher.publishOrderEvent("created", order.getId(), event);
        }

        private void publishOrderAcceptedEvent(Order order, User shipper) {
        OrderAcceptedEvent event = OrderAcceptedEvent.builder()
            .eventType("ORDER_ACCEPTED")
            .timestamp(System.currentTimeMillis())
            .orderId(order.getId())
            .customerId(order.getCustomer().getId())
            .storeId(order.getStore().getId())
            .shipperId(shipper.getId())
            .shipperName(shipper.getFullName())
            .shipperPhone(shipper.getPhoneNumber())
            .acceptedAt(LocalDateTime.now())
            .build();

        messagePublisher.publishOrderEvent("accepted", order.getId(), event);
        }

        private void publishOrderStatusChangedEvent(
            Order order,
            OrderStatus oldStatus,
            OrderStatus newStatus,
            String reason) {
        OrderStatusChangedEvent event = OrderStatusChangedEvent.builder()
            .eventType("ORDER_STATUS_CHANGED")
            .timestamp(System.currentTimeMillis())
            .orderId(order.getId())
            .customerId(order.getCustomer().getId())
            .storeId(order.getStore().getId())
            .shipperId(order.getShipper() != null ? order.getShipper().getId() : null)
            .oldStatus(oldStatus)
            .newStatus(newStatus)
            .statusDescription(newStatus.name())
            .changedAt(LocalDateTime.now())
            .reason(reason)
            .build();

        messagePublisher.publishOrderEvent("status", order.getId(), event);
        }

    /**
     * Validate chuyển trạng thái có hợp lệ không
     * State Machine:
     * - PENDING → CONFIRMED (Store owner)
     * - PENDING → CANCELLED (Customer/Store)
     * - CONFIRMED → PICKING_UP (Shipper - khi nhận đơn)
     * - CONFIRMED → CANCELLED (Customer/Store)
     * - PICKING_UP → DELIVERING (Shipper)
     * - DELIVERING → DELIVERED (Shipper)
     * - DELIVERING → CANCELLED (Không được phép - đã lấy hàng rồi)
     */
    private void validateStatusTransition(Order order, OrderStatus newStatus, User user) {
        OrderStatus currentStatus = order.getStatus();

        // Không cho phép chuyển sang trạng thái hiện tại
        if (currentStatus == newStatus) {
            throw new BadRequestException("Đơn hàng đã ở trạng thái " + newStatus);
        }

        // Validate theo role
        switch (currentStatus) {
            case PENDING:
                if (newStatus == OrderStatus.CONFIRMED) {
                    // Chỉ Store owner mới confirm
                    if (!user.getRole().equals(User.UserRole.STORE) ||
                            !order.getStore().getOwner().getId().equals(user.getId())) {
                        throw new UnauthorizedException("Chỉ chủ cửa hàng mới có thể xác nhận đơn hàng");
                    }
                } else if (newStatus == OrderStatus.CANCELLED) {
                    // Customer hoặc Store có thể hủy
                    boolean isCustomer = order.getCustomer().getId().equals(user.getId());
                    boolean isStoreOwner = user.getRole().equals(User.UserRole.STORE) &&
                            order.getStore().getOwner().getId().equals(user.getId());
                    if (!isCustomer && !isStoreOwner) {
                        throw new UnauthorizedException("Bạn không có quyền hủy đơn hàng này");
                    }
                } else {
                    throw new BadRequestException(
                            "Đơn hàng chỉ có thể chuyển từ PENDING sang CONFIRMED hoặc CANCELLED");
                }
                break;

            case CONFIRMED:
                if (newStatus == OrderStatus.PICKING_UP) {
                    // Tự động chuyển khi shipper nhận đơn (không cần validate ở đây)
                } else if (newStatus == OrderStatus.CANCELLED) {
                    // Customer hoặc Store có thể hủy
                    boolean isCustomer = order.getCustomer().getId().equals(user.getId());
                    boolean isStoreOwner = user.getRole().equals(User.UserRole.STORE) &&
                            order.getStore().getOwner().getId().equals(user.getId());
                    if (!isCustomer && !isStoreOwner) {
                        throw new UnauthorizedException("Bạn không có quyền hủy đơn hàng này");
                    }
                } else {
                    throw new BadRequestException(
                            "Đơn hàng chỉ có thể chuyển từ CONFIRMED sang PICKING_UP hoặc CANCELLED");
                }
                break;

            case PICKING_UP:
                if (newStatus == OrderStatus.DELIVERING) {
                    // Chỉ shipper nhận đơn mới được chuyển
                    if (order.getShipper() == null || !order.getShipper().getId().equals(user.getId())) {
                        throw new UnauthorizedException("Chỉ tài xế nhận đơn mới có thể cập nhật trạng thái");
                    }
                } else {
                    throw new BadRequestException(
                            "Đơn hàng chỉ có thể chuyển từ PICKING_UP sang DELIVERING");
                }
                break;

            case DELIVERING:
                if (newStatus == OrderStatus.DELIVERED) {
                    // Chỉ shipper nhận đơn mới được chuyển
                    if (order.getShipper() == null || !order.getShipper().getId().equals(user.getId())) {
                        throw new UnauthorizedException("Chỉ tài xế nhận đơn mới có thể cập nhật trạng thái");
                    }
                } else {
                    throw new BadRequestException(
                            "Đơn hàng đang giao không thể hủy. Chỉ có thể chuyển sang DELIVERED");
                }
                break;

            case DELIVERED:
            case CANCELLED:
                throw new BadRequestException("Đơn hàng đã hoàn tất/hủy, không thể thay đổi trạng thái");

            default:
                throw new BadRequestException("Trạng thái không hợp lệ");
        }
    }

    /**
     * Map Order entity sang OrderResponse DTO
     */
    private OrderResponse mapToOrderResponse(Order order) {
        List<OrderItemResponse> items = order.getOrderItems().stream()
                .map(item -> OrderItemResponse.builder()
                        .id(item.getId())
                        .productId(item.getProductUnit().getProduct().getId())
                        .productName(item.getProductUnit().getProduct().getName())
                        .productImageUrl(item.getProductUnit().getProduct().getImageUrl())
                        .unitName(item.getProductUnit().getUnitName())
                        .unitPrice(item.getUnitPrice())
                        .quantity(item.getQuantity())
                        .subtotal(item.getSubtotal())
                        .build())
                .collect(Collectors.toList());

        return OrderResponse.builder()
                .id(order.getId())
                .customerId(order.getCustomer().getId())
                .customerName(order.getCustomer().getFullName())
                .customerPhone(order.getCustomer().getPhoneNumber())
                .storeId(order.getStore().getId())
                .storeName(order.getStore().getStoreName())
                .storeAddress(order.getStore().getAddress())
                .shipperId(order.getShipper() != null ? order.getShipper().getId() : null)
                .shipperName(order.getShipper() != null ? order.getShipper().getFullName() : null)
                .shipperPhone(order.getShipper() != null ? order.getShipper().getPhoneNumber() : null)
                .status(order.getStatus())
                .totalAmount(order.getTotalAmount())
                .shippingFee(order.getShippingFee())
                .grandTotal(order.getTotalAmount().add(order.getShippingFee()))
                .deliveryAddress(order.getDeliveryAddress())
                .podImageUrl(order.getPodImageUrl())
                .cancelReason(order.getCancelReason())
                .createdAt(order.getCreatedAt())
                .items(items)
                .build();
    }
}
