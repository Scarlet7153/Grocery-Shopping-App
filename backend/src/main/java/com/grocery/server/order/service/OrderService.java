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
import com.grocery.server.product.entity.ProductUnitMapping;
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
import com.grocery.server.notification.service.NotificationService;
import com.grocery.server.notification.document.Notification;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

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
    private final NotificationService notificationService;

    // Phí ship cố định (VNĐ) - Có thể cấu hình trong application.properties sau
    private static final BigDecimal SHIPPING_FEE = new BigDecimal("15000.00");

    /**
     * Tạo đơn hàng mới
     * 
     * @param request    Thông tin đơn hàng
     * @param customerId ID khách hàng
     * @return Thông tin đơn hàng vừa tạo
     */
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
            BigDecimal requestedQuantity = itemRequest.getQuantity();

            // Validate ProductUnitMapping
            ProductUnitMapping productUnitMapping = productRepository.findProductUnitMappingById(itemRequest.getProductUnitMappingId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                    "Không tìm thấy biến thể sản phẩm ID: " + itemRequest.getProductUnitMappingId()));

            // Kiểm tra sản phẩm có thuộc cửa hàng này không
            if (!productUnitMapping.getProduct().getStore().getId().equals(request.getStoreId())) {
                throw new BadRequestException(
                "Sản phẩm '" + productUnitMapping.getProduct().getName() + "' không thuộc cửa hàng này");
            }

            // Kiểm tra tồn kho
            BigDecimal availableStock = BigDecimal.valueOf(productUnitMapping.getStockQuantity());
            if (availableStock.compareTo(requestedQuantity) < 0) {
                throw new BadRequestException(
                "Sản phẩm '" + productUnitMapping.getProduct().getName() + " - " + productUnitMapping.getDisplayUnitName() +
                    "' chỉ còn " + productUnitMapping.getStockQuantity() + " (yêu cầu: " + requestedQuantity + ")"
                );
            }

            int deductedStock;
            try {
                deductedStock = requestedQuantity.intValueExact();
            } catch (ArithmeticException ex) {
                throw new BadRequestException(
                        "Số lượng đặt cho biến thể phải là số nguyên do tồn kho hiện được quản lý theo đơn vị nguyên");
            }

            // Tạo OrderItem
            OrderItem orderItem = OrderItem.builder()
                    .order(order)
                .productUnitMapping(productUnitMapping)
                    .quantity(requestedQuantity)
                .unitPrice(productUnitMapping.getPrice())
                    .build();

            orderItems.add(orderItem);
            totalAmount = totalAmount.add(orderItem.getSubtotal());

            // Trừ tồn kho
                productUnitMapping.setStockQuantity(productUnitMapping.getStockQuantity() - deductedStock);
            log.info("Trừ {} sản phẩm '{}', còn lại: {}", 
                    requestedQuantity, 
                    productUnitMapping.getProduct().getName(), 
                    productUnitMapping.getStockQuantity());
        }

        order.setTotalAmount(totalAmount);
        order.setOrderItems(orderItems);

        // Lưu đơn hàng
        Order savedOrder = orderRepository.save(order);
        log.info("Đã tạo đơn hàng #{} với tổng tiền: {} VNĐ", savedOrder.getId(), totalAmount);
        publishOrderCreatedEvent(savedOrder);

        // Thông báo đến Store owner về đơn hàng mới
        if (store.getOwner() != null) {
            notificationService.createAndSend(
                store.getOwner().getId(),
                Notification.ORDER_CREATED,
                "Đơn hàng mới #" + savedOrder.getId(),
                "Khách hàng " + savedOrder.getCustomer().getFullName()
                    + " đặt đơn " + savedOrder.getTotalAmount().toPlainString() + " VNĐ",
                savedOrder.getId(),
                "ORDER"
            );
        }

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

        // Chỉ lấy đơn hàng đã thanh toán thành công:
        // - COD: luôn hiển thị
        // - MOMO: chỉ hiển thị khi thanh toán thành công
        List<Order> orders = orderRepository.findPaidOrdersByStoreId(store.getId());
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
     * Lấy tất cả đơn hàng (dành cho admin)
     *
     * @return Danh sách đơn hàng, sắp xếp theo thời gian mới nhất
     */
    public List<OrderResponse> getAllOrders() {
        List<Order> orders = orderRepository.findAllOrdersSorted();
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy tất cả đơn hàng có phân trang và bộ lọc (dành cho admin)
     */
    public Page<OrderResponse> getAllOrdersPaginated(int page, int size, String sortBy, String sortDir,
                                                     Long storeId, Order.OrderStatus status,
                                                     LocalDateTime from, LocalDateTime to) {
        Sort.Direction direction = "desc".equalsIgnoreCase(sortDir) ? Sort.Direction.DESC : Sort.Direction.ASC;
        String sortField = (sortBy == null || sortBy.isBlank()) ? "createdAt" : sortBy;
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.max(1, size), Sort.by(direction, sortField));

        Page<Order> ordersPage = orderRepository.findAllWithFilters(storeId, status, from, to, pageable);
        return ordersPage.map(this::mapToOrderResponse);
    }

    /**
     * Cập nhật trạng thái đơn hàng
     * 
     * @param orderId ID đơn hàng
     * @param request Thông tin cập nhật
     * @param userId  ID người thực hiện
     * @return Thông tin đơn hàng sau khi cập nhật
     */
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
        sendOrderNotifications(order, request.getNewStatus(), request.getCancelReason());

        return mapToOrderResponse(order);
    }

    /**
     * Tài xế nhận đơn
     * 
     * @param orderId   ID đơn hàng
     * @param shipperId ID tài xế
     * @return Thông tin đơn hàng
     */
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

        // Thông báo cho khách hàng và tài xế
        notificationService.createAndSend(
            order.getCustomer().getId(), Notification.SHIPPER_ASSIGNED,
            "Shipper đã nhận đơn của bạn",
            "Shipper " + shipper.getFullName() + " (" + shipper.getPhoneNumber() + ") đang trên đường đến cửa hàng",
            orderId, "ORDER");

        notificationService.createAndSend(
            order.getStore().getOwner().getId(), Notification.SHIPPER_ASSIGNED,
            "Có shipper nhận đơn #" + orderId,
            "Shipper " + shipper.getFullName() + " đã nhận đơn hàng",
            orderId, "ORDER");

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

    private void sendOrderNotifications(Order order, OrderStatus newStatus, String reason) {
        Long customerId = order.getCustomer().getId();
        Long storeOwnerId = order.getStore().getOwner().getId();
        Long orderId = order.getId();

        switch (newStatus) {
            case CONFIRMED -> notificationService.createAndSend(
                customerId, Notification.ORDER_CONFIRMED,
                "Đơn hàng #" + orderId + " đã được xác nhận",
                "Cửa hàng " + order.getStore().getStoreName() + " đã xác nhận đơn của bạn",
                orderId, "ORDER");

            case PICKING_UP -> notificationService.createAndSend(
                customerId, Notification.ORDER_PICKING_UP,
                "Shipper đang lấy hàng",
                "Shipper " + order.getShipper().getFullName() + " đang đến lấy hàng tại cửa hàng",
                orderId, "ORDER");

            case DELIVERING -> notificationService.createAndSend(
                customerId, Notification.ORDER_DELIVERING,
                "Đơn hàng đang trên đường giao",
                "Shipper " + order.getShipper().getFullName() + " đang giao hàng đến bạn",
                orderId, "ORDER");

            case DELIVERED -> {
                notificationService.createAndSend(
                    customerId, Notification.ORDER_DELIVERED,
                    "Giao hàng thành công! 🎉",
                    "Đơn hàng #" + orderId + " đã được giao. Hãy đánh giá trải nghiệm của bạn!",
                    orderId, "ORDER");
                notificationService.createAndSend(
                    storeOwnerId, Notification.ORDER_DELIVERED,
                    "Đơn hàng #" + orderId + " hoàn thành",
                    "Shipper đã giao thành công cho khách hàng " + order.getCustomer().getFullName(),
                    orderId, "ORDER");
            }

            case CANCELLED -> {
                notificationService.createAndSend(
                    customerId, Notification.ORDER_CANCELLED,
                    "Đơn hàng #" + orderId + " đã bị hủy",
                    reason != null ? "Lý do: " + reason : "Đơn hàng của bạn đã bị hủy",
                    orderId, "ORDER");
                notificationService.createAndSend(
                    storeOwnerId, Notification.ORDER_CANCELLED,
                    "Đơn hàng #" + orderId + " bị hủy",
                    reason != null ? "Lý do: " + reason : "Đơn hàng đã bị hủy",
                    orderId, "ORDER");
            }

            default -> {}
        }
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
                    // Không cho phép hủy khi đã CONFIRMED
                    throw new BadRequestException(
                            "Đơn hàng đã được xác nhận, không thể hủy. Vui lòng liên hệ cửa hàng.");
                } else {
                    throw new BadRequestException(
                            "Đơn hàng chỉ có thể chuyển từ CONFIRMED sang PICKING_UP");
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
                .productId(item.getProductUnitMapping().getProduct().getId())
                .productName(item.getProductUnitMapping().getProduct().getName())
                .productImageUrl(item.getProductUnitMapping().getProduct().getImageUrl())
                .unitName(item.getProductUnitMapping().getDisplayUnitName())
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
                .paymentMethod(order.getPayments() != null && !order.getPayments().isEmpty()
                        ? order.getPayments().get(0).getPaymentMethod().name()
                        : null)
                .build();
    }
}
