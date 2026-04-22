package com.grocery.server.order.service;

import com.grocery.server.messaging.dto.OrderAcceptedEvent;
import com.grocery.server.messaging.dto.OrderCreatedEvent;
import com.grocery.server.messaging.dto.OrderStatusChangedEvent;
import com.grocery.server.messaging.publisher.RedisMessagePublisher;
import com.grocery.server.order.dto.request.CreateOrderRequest;
import com.grocery.server.order.dto.request.UpdateOrderStatusRequest;
import com.grocery.server.order.dto.response.OrderItemResponse;
import com.grocery.server.order.dto.response.OrderResponse;
import com.grocery.server.order.dto.response.OrderStatisticsResponse;
import com.grocery.server.order.dto.response.OrderStatisticsResponse.MonthlyRevenueDto;
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
import org.springframework.transaction.annotation.Transactional;

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
        log.info("Khách hàng {} đang tạo đơn hàng liên cửa hàng", customerId);

        // 1. Validate customer
        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khách hàng"));

        if (!customer.getRole().equals(User.UserRole.CUSTOMER)) {
            throw new BadRequestException("Chỉ khách hàng mới có thể đặt hàng");
        }

        // 2. Chuẩn bị đơn hàng
        List<OrderItem> orderItems = new ArrayList<>();
        BigDecimal totalAmount = BigDecimal.ZERO;
        List<Store> involvedStores = new ArrayList<>();

        // Dùng phí ship từ FE nếu có, ngược lại fallback về mặc định
        BigDecimal shippingFee = (request.getShippingFee() != null && request.getShippingFee().compareTo(BigDecimal.ZERO) > 0)
                ? request.getShippingFee()
                : SHIPPING_FEE;

        Order order = Order.builder()
                .customer(customer)
                .status(OrderStatus.PENDING)
                .deliveryAddress(request.getDeliveryAddress())
                .shippingFee(shippingFee)
                .build();

        for (var itemRequest : request.getItems()) {
            BigDecimal requestedQuantity = itemRequest.getQuantity();

            // Validate ProductUnitMapping
            ProductUnitMapping productUnitMapping = productRepository.findProductUnitMappingById(itemRequest.getProductUnitMappingId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                    "Không tìm thấy biến thể sản phẩm ID: " + itemRequest.getProductUnitMappingId()));

            Store itemStore = productUnitMapping.getProduct().getStore();
            if (!involvedStores.contains(itemStore)) {
                involvedStores.add(itemStore);
            }

            if (itemStore != null && !itemStore.getIsOpen()) {
                throw new BadRequestException("Cửa hàng '" + itemStore.getStoreName() + "' hiện không hoạt động");
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
        }

        // Gán store chính (nếu chỉ có 1 cửa hàng thì gán, nếu nhiều thì để null hoặc gán cửa hàng đầu tiên)
        if (!involvedStores.isEmpty()) {
            order.setStore(involvedStores.get(0));
        }

        order.setTotalAmount(totalAmount);
        order.setOrderItems(orderItems);

        // Lưu đơn hàng
        Order savedOrder = orderRepository.save(order);
        log.info("Đã tạo đơn hàng #{} (liên cửa hàng) với tổng tiền: {} VNĐ", savedOrder.getId(), totalAmount);
        publishOrderCreatedEvent(savedOrder);

        // Thông báo đến TẤT CẢ Store owner liên quan
        for (Store s : involvedStores) {
            if (s.getOwner() != null) {
                notificationService.createAndSend(
                    s.getOwner().getId(),
                    Notification.ORDER_CREATED,
                    "Đơn hàng mới #" + savedOrder.getId(),
                    "Khách hàng " + savedOrder.getCustomer().getFullName()
                        + " đặt đơn có sản phẩm của bạn. Tổng đơn: " + savedOrder.getTotalAmount().toPlainString() + " VNĐ",
                    savedOrder.getId(),
                    "ORDER"
                );
            }
        }

        return mapToOrderResponse(savedOrder);
    }

    /**
     * Lấy đơn hàng theo ID
     * 
     * @param orderId ID đơn hàng
     * @return Thông tin đơn hàng
     */
    @Transactional(readOnly = true)
    public OrderResponse getOrderById(Long orderId) {
        Order order = orderRepository.findByIdWithFullDetails(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn hàng"));
        return mapToOrderResponse(order);
    }

    /**
     * Lấy tất cả đơn hàng của khách hàng
     * 
     * @param customerId ID khách hàng
     * @return Danh sách đơn hàng
     */
    @Transactional(readOnly = true)
    public List<OrderResponse> getOrdersByCustomer(Long customerId) {
        List<Order> orders = orderRepository.findByCustomerIdWithDetails(customerId);
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
    @Transactional(readOnly = true)
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
    @Transactional(readOnly = true)
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
    @Transactional(readOnly = true)
    public List<OrderResponse> getOrdersByShipper(Long shipperId) {
        List<Order> orders = orderRepository.findByShipperIdWithDetails(shipperId);
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy danh sách đơn hàng có thể nhận (cho tài xế)
     * 
     * @return Danh sách đơn hàng đang chờ tài xế
     */
    @Transactional(readOnly = true)
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
    @Transactional(readOnly = true)
    public List<OrderResponse> getAllOrders() {
        List<Order> orders = orderRepository.findAllOrdersSorted();
        return orders.stream()
                .map(this::mapToOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy tất cả đơn hàng có phân trang và bộ lọc (dành cho admin)
     */
    @Transactional(readOnly = true)
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
     * Lấy đơn hàng của khách hàng - CÓ PHÂN TRANG
     */
    @Transactional(readOnly = true)
    public Page<OrderResponse> getOrdersByCustomerPaginated(Long customerId, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.max(1, size));
        Page<Order> ordersPage = orderRepository.findByCustomerId(customerId, pageable);
        return ordersPage.map(this::mapToOrderResponse);
    }

    /**
     * Lấy đơn hàng của cửa hàng - CÓ PHÂN TRANG
     */
    @Transactional(readOnly = true)
    public Page<OrderResponse> getOrdersByStoreOwnerPaginated(Long userId, int page, int size) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy user"));

        if (!user.getRole().equals(User.UserRole.STORE)) {
            throw new BadRequestException("Chỉ cửa hàng mới có thể xem đơn hàng của mình");
        }

        Store store = user.getStore();
        if (store == null) {
            throw new ResourceNotFoundException("User này chưa có cửa hàng");
        }

        Pageable pageable = PageRequest.of(Math.max(0, page), Math.max(1, size));
        Page<Order> ordersPage = orderRepository.findPaidOrdersByStoreId(store.getId(), pageable);
        return ordersPage.map(this::mapToOrderResponse);
    }

    /**
     * Lấy đơn hàng của tài xế - CÓ PHÂN TRANG
     */
    @Transactional(readOnly = true)
    public Page<OrderResponse> getOrdersByShipperPaginated(Long shipperId, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.max(1, size));
        Page<Order> ordersPage = orderRepository.findByShipperId(shipperId, pageable);
        return ordersPage.map(this::mapToOrderResponse);
    }

    /**
     * Lấy đơn hàng có thể nhận (cho tài xế) - CÓ PHÂN TRANG
     */
    @Transactional(readOnly = true)
    public Page<OrderResponse> getAvailableOrdersPaginated(int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.max(1, size));
        Page<Order> ordersPage = orderRepository.findAvailableOrdersForShippers(pageable);
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
            "Shipper " + shipper.getFullName() + " (" + shipper.getPhoneNumber() + ") đang chuẩn bị đi lấy hàng",
            orderId, "ORDER");

        List<Store> involvedStores = order.getOrderItems().stream()
                .map(oi -> oi.getProductUnitMapping().getProduct().getStore())
                .distinct().collect(Collectors.toList());

        for (Store s : involvedStores) {
            if (s.getOwner() != null) {
                notificationService.createAndSend(
                    s.getOwner().getId(), Notification.SHIPPER_ASSIGNED,
                    "Có shipper nhận đơn #" + orderId,
                    "Shipper " + shipper.getFullName() + " đã nhận đơn hàng",
                    orderId, "ORDER");
            }
        }

        return mapToOrderResponse(order);
    }

        private void publishOrderCreatedEvent(Order order) {
        boolean isMultiStore = order.getOrderItems().stream()
            .map(oi -> oi.getProductUnitMapping().getProduct().getStore().getId())
            .distinct().count() > 1;

        String storeName = isMultiStore
            ? "Đơn hàng liên cửa hàng (" + order.getOrderItems().stream()
                .map(oi -> oi.getProductUnitMapping().getProduct().getStore().getStoreName())
                .distinct().limit(2).collect(Collectors.joining(", ")) + "...)"
            : (order.getStore() != null ? order.getStore().getStoreName() : "Nhiều cửa hàng");

        OrderCreatedEvent event = OrderCreatedEvent.builder()
            .eventType("ORDER_CREATED")
            .timestamp(System.currentTimeMillis())
            .orderId(order.getId())
            .customerId(order.getCustomer().getId())
            .storeId(order.getStore() != null ? order.getStore().getId() : null)
            .storeName(storeName)
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
            .storeId(order.getStore() != null ? order.getStore().getId() : null)
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
            .storeId(order.getStore() != null ? order.getStore().getId() : null)
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
        Long orderId = order.getId();

        List<Store> involvedStores = order.getOrderItems().stream()
                .map(oi -> oi.getProductUnitMapping().getProduct().getStore())
                .distinct().collect(Collectors.toList());

        boolean isMultiStore = involvedStores.size() > 1;
        String storeDisplay = isMultiStore ? "Các cửa hàng" : (involvedStores.isEmpty() ? "Cửa hàng" : involvedStores.get(0).getStoreName());

        switch (newStatus) {
            case CONFIRMED -> notificationService.createAndSend(
                customerId, Notification.ORDER_CONFIRMED,
                "Đơn hàng #" + orderId + " đã được xác nhận",
                storeDisplay + " đã xác nhận đơn của bạn",
                orderId, "ORDER");

            case PICKING_UP -> notificationService.createAndSend(
                customerId, Notification.ORDER_PICKING_UP,
                "Shipper đang lấy hàng",
                "Shipper " + order.getShipper().getFullName() + " đang đến các cửa hàng để lấy hàng",
                orderId, "ORDER");

            case DELIVERING -> notificationService.createAndSend(
                customerId, Notification.ORDER_DELIVERING,
                "Đơn hàng đang trên đường giao",
                "Shipper " + order.getShipper().getFullName() + " đang giao hàng đến bạn",
                orderId, "ORDER");

            case DELIVERED -> notificationService.createAndSend(
                    customerId, Notification.ORDER_DELIVERED,
                    "Giao hàng thành công! 🎉",
                    "Đơn hàng #" + orderId + " đã được giao. Hãy đánh giá trải nghiệm của bạn!",
                    orderId, "ORDER");

            case CANCELLED -> notificationService.createAndSend(
                    customerId, Notification.ORDER_CANCELLED,
                    "Đơn hàng #" + orderId + " đã bị hủy",
                    reason != null ? "Lý do: " + reason : "Đơn hàng của bạn đã bị hủy",
                    orderId, "ORDER");

            default -> {}
        }

        // Thông báo đến tất cả Store Owners liên quan
        for (Store store : involvedStores) {
            if (store.getOwner() == null) continue;
            Long storeOwnerId = store.getOwner().getId();

            if (newStatus == OrderStatus.DELIVERED) {
                notificationService.createAndSend(
                    storeOwnerId, Notification.ORDER_DELIVERED,
                    "Đơn hàng #" + orderId + " hoàn thành",
                    "Shipper đã giao thành công phần sản phẩm của bạn cho khách hàng " + order.getCustomer().getFullName(),
                    orderId, "ORDER");
            } else if (newStatus == OrderStatus.CANCELLED) {
                notificationService.createAndSend(
                    storeOwnerId, Notification.ORDER_CANCELLED,
                    "Đơn hàng #" + orderId + " bị hủy",
                    reason != null ? "Lý do: " + reason : "Đơn hàng đã bị hủy",
                    orderId, "ORDER");
            }
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
                    // Check if user is owner of at least one involved store
                    boolean isAuthorizedStoreOwner = order.getOrderItems().stream()
                        .map(oi -> oi.getProductUnitMapping().getProduct().getStore().getOwner())
                        .anyMatch(owner -> owner != null && owner.getId().equals(user.getId()));
                        
                    if (!user.getRole().equals(User.UserRole.STORE) || !isAuthorizedStoreOwner) {
                        throw new UnauthorizedException("Chỉ chủ cửa hàng liên quan mới có thể xác nhận đơn hàng");
                    }
                } else if (newStatus == OrderStatus.CANCELLED) {
                    // Customer hoặc Store có thể hủy
                    boolean isCustomer = order.getCustomer().getId().equals(user.getId());
                    boolean isAuthorizedStoreOwner = order.getOrderItems().stream()
                        .map(oi -> oi.getProductUnitMapping().getProduct().getStore().getOwner())
                        .anyMatch(owner -> owner != null && owner.getId().equals(user.getId()));

                    if (!isCustomer && !isAuthorizedStoreOwner) {
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

        List<Store> involvedStores = order.getOrderItems().stream()
                .map(oi -> oi.getProductUnitMapping().getProduct().getStore())
                .distinct().collect(Collectors.toList());

        boolean isMultiStore = involvedStores.size() > 1;
        Long storeId = isMultiStore ? null : (involvedStores.isEmpty() ? null : involvedStores.get(0).getId());
        String storeName = isMultiStore ? "Đơn hàng liên cửa hàng" : (involvedStores.isEmpty() ? "Nhiều cửa hàng" : involvedStores.get(0).getStoreName());
        String storeAddress = isMultiStore ? "Nhiều địa chỉ" : (involvedStores.isEmpty() ? "" : involvedStores.get(0).getAddress());

        List<com.grocery.server.order.dto.response.StoreInfoResponse> storeInfos = involvedStores.stream()
                .map(s -> com.grocery.server.order.dto.response.StoreInfoResponse.builder()
                        .id(s.getId())
                        .name(s.getStoreName())
                        .address(s.getAddress())
                        .build())
                .collect(Collectors.toList());

        return OrderResponse.builder()
                .id(order.getId())
                .customerId(order.getCustomer().getId())
                .customerName(order.getCustomer().getFullName())
                .customerPhone(order.getCustomer().getPhoneNumber())
                .storeId(storeId)
                .storeName(storeName)
                .storeAddress(storeAddress)
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
                .stores(storeInfos)
                .build();
    }

    /**
     * Lấy thống kê đơn hàng cho Dashboard Admin
     */
    public OrderStatisticsResponse getOrderStatistics() {
        java.time.LocalDateTime now = java.time.LocalDateTime.now();

        // Tháng hiện tại
        java.time.LocalDateTime currentMonthStart = now.withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
        java.time.LocalDateTime nextMonthStart = currentMonthStart.plusMonths(1);
        java.math.BigDecimal currentMonthRevenue = orderRepository.getRevenueBetween(currentMonthStart, nextMonthStart);
        if (currentMonthRevenue == null) currentMonthRevenue = java.math.BigDecimal.ZERO;

        // Tháng trước
        java.time.LocalDateTime prevMonthStart = currentMonthStart.minusMonths(1);
        java.math.BigDecimal previousMonthRevenue = orderRepository.getRevenueBetween(prevMonthStart, currentMonthStart);
        if (previousMonthRevenue == null) previousMonthRevenue = java.math.BigDecimal.ZERO;

        // % tăng trưởng
        Double growth = 0.0;
        if (previousMonthRevenue.compareTo(java.math.BigDecimal.ZERO) > 0) {
            growth = currentMonthRevenue.subtract(previousMonthRevenue)
                    .divide(previousMonthRevenue, 4, java.math.RoundingMode.HALF_UP)
                    .multiply(new java.math.BigDecimal("100"))
                    .doubleValue();
        }

        // Doanh thu 12 tháng
        List<Object[]> monthlyData = orderRepository.getMonthlyRevenueLast12Months();
        List<MonthlyRevenueDto> monthlyRevenue = monthlyData.stream()
                .map(row -> {
                    String month = (String) row[0];
                    String monthLabel = month;
                    try {
                        String[] parts = month.split("-");
                        monthLabel = parts[1] + "/" + parts[0];
                    } catch (Exception ignored) {}
                    return MonthlyRevenueDto.builder()
                            .month(month)
                            .monthLabel(monthLabel)
                            .revenue(row[1] != null ? (java.math.BigDecimal) row[1] : java.math.BigDecimal.ZERO)
                            .orderCount(row[2] != null ? ((Number) row[2]).longValue() : 0L)
                            .build();
                })
                .collect(Collectors.toList());

        // Tổng doanh thu và tổng đơn
        java.math.BigDecimal totalRevenue = orderRepository.getTotalRevenue();
        if (totalRevenue == null) totalRevenue = java.math.BigDecimal.ZERO;

        Long totalOrders = orderRepository.count();

        return OrderStatisticsResponse.builder()
                .currentMonthRevenue(currentMonthRevenue)
                .previousMonthRevenue(previousMonthRevenue)
                .monthOverMonthGrowth(growth)
                .totalRevenue(totalRevenue)
                .totalOrders(totalOrders)
                .monthlyRevenue(monthlyRevenue)
                .build();
    }
}
