package com.grocery.server.order.repository;

import com.grocery.server.order.entity.Order;
import com.grocery.server.order.entity.Order.OrderStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository: OrderRepository
 * Mô tả: Quản lý truy vấn database cho Order
 */
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    /**
     * Lấy tất cả đơn hàng của một khách hàng
     * @param customerId ID khách hàng
     * @return Danh sách đơn hàng, sắp xếp theo thời gian mới nhất
     */
    @Query("SELECT o FROM Order o WHERE o.customer.id = :customerId ORDER BY o.createdAt DESC")
    List<Order> findByCustomerId(@Param("customerId") Long customerId);

    /**
     * Lấy đơn hàng của khách hàng - CÓ PHÂN TRANG
     */
    @Query("SELECT o FROM Order o WHERE o.customer.id = :customerId ORDER BY o.createdAt DESC")
    Page<Order> findByCustomerId(@Param("customerId") Long customerId, Pageable pageable);

    /**
     * Lấy tất cả đơn hàng của một cửa hàng (hoặc chứa sản phẩm của cửa hàng đó)
     * @param storeId ID cửa hàng
     * @return Danh sách đơn hàng, sắp xếp theo thời gian mới nhất
     */
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN o.orderItems oi " +
           "WHERE o.store.id = :storeId OR oi.productUnitMapping.product.store.id = :storeId " +
           "ORDER BY o.createdAt DESC")
    List<Order> findByStoreId(@Param("storeId") Long storeId);

    /**
     * Lấy đơn hàng của cửa hàng đã thanh toán thành công
     * - COD: luôn hiển thị (payment_method = COD)
     * - MOMO: chỉ hiển thị khi thanh toán thành công (payment_status = SUCCESS)
     * @param storeId ID cửa hàng
     * @return Danh sách đơn hàng đã thanh toán
     */
    @Query("SELECT DISTINCT o FROM Order o JOIN o.payments p LEFT JOIN o.orderItems oi " +
           "WHERE (o.store.id = :storeId OR oi.productUnitMapping.product.store.id = :storeId) " +
           "AND (p.paymentMethod = 'COD' OR (p.paymentMethod = 'MOMO' AND p.status = 'SUCCESS')) " +
           "ORDER BY o.createdAt DESC")
    List<Order> findPaidOrdersByStoreId(@Param("storeId") Long storeId);

    /**
     * Lấy đơn hàng đã thanh toán của cửa hàng - CÓ PHÂN TRANG
     */
    @Query("SELECT DISTINCT o FROM Order o JOIN o.payments p LEFT JOIN o.orderItems oi " +
           "WHERE (o.store.id = :storeId OR oi.productUnitMapping.product.store.id = :storeId) " +
           "AND (p.paymentMethod = 'COD' OR (p.paymentMethod = 'MOMO' AND p.status = 'SUCCESS')) " +
           "ORDER BY o.createdAt DESC")
    Page<Order> findPaidOrdersByStoreId(@Param("storeId") Long storeId, Pageable pageable);

    /**
     * Lấy tất cả đơn hàng của một tài xế
     * @param shipperId ID tài xế
     * @return Danh sách đơn hàng, sắp xếp theo thời gian mới nhất
     */
    @Query("SELECT o FROM Order o WHERE o.shipper.id = :shipperId ORDER BY o.createdAt DESC")
    List<Order> findByShipperId(@Param("shipperId") Long shipperId);

    /**
     * Lấy đơn hàng của tài xế - CÓ PHÂN TRANG
     */
    @Query("SELECT o FROM Order o WHERE o.shipper.id = :shipperId ORDER BY o.createdAt DESC")
    Page<Order> findByShipperId(@Param("shipperId") Long shipperId, Pageable pageable);

    /**
     * Lấy đơn hàng theo trạng thái của một cửa hàng
     * @param storeId ID cửa hàng
     * @param status Trạng thái đơn hàng
     * @return Danh sách đơn hàng
     */
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN o.orderItems oi " +
           "WHERE (o.store.id = :storeId OR oi.productUnitMapping.product.store.id = :storeId) " +
           "AND o.status = :status ORDER BY o.createdAt DESC")
    List<Order> findByStoreIdAndStatus(@Param("storeId") Long storeId, @Param("status") OrderStatus status);

    /**
     * Lấy đơn hàng theo trạng thái của một khách hàng
     * @param customerId ID khách hàng
     * @param status Trạng thái đơn hàng
     * @return Danh sách đơn hàng
     */
    @Query("SELECT o FROM Order o WHERE o.customer.id = :customerId AND o.status = :status ORDER BY o.createdAt DESC")
    List<Order> findByCustomerIdAndStatus(@Param("customerId") Long customerId, @Param("status") OrderStatus status);

    /**
     * Đếm số đơn hàng của một cửa hàng theo trạng thái
     * @param storeId ID cửa hàng
     * @param status Trạng thái
     * @return Số lượng đơn hàng
     */
    @Query("SELECT COUNT(DISTINCT o) FROM Order o LEFT JOIN o.orderItems oi " +
           "WHERE (o.store.id = :storeId OR oi.productUnitMapping.product.store.id = :storeId) " +
           "AND o.status = :status")
    Long countByStoreIdAndStatus(@Param("storeId") Long storeId, @Param("status") OrderStatus status);

    /**
     * Lấy tất cả đơn hàng đang chờ tài xế nhận (CONFIRMED)
     * Chỉ lấy đơn đã thanh toán thành công (COD hoặc MOMO SUCCESS)
     * @return Danh sách đơn hàng chưa có shipper và đang ở trạng thái CONFIRMED
     */
    @Query("SELECT DISTINCT o FROM Order o JOIN o.payments p " +
           "WHERE o.status = 'CONFIRMED' AND o.shipper IS NULL " +
           "AND (p.paymentMethod = 'COD' OR (p.paymentMethod = 'MOMO' AND p.status = 'SUCCESS')) " +
           "ORDER BY o.createdAt ASC")
    List<Order> findAvailableOrdersForShippers();

    /**
     * Lấy đơn hàng chờ shipper nhận - CÓ PHÂN TRANG
     */
    @Query("SELECT DISTINCT o FROM Order o JOIN o.payments p " +
           "WHERE o.status = 'CONFIRMED' AND o.shipper IS NULL " +
           "AND (p.paymentMethod = 'COD' OR (p.paymentMethod = 'MOMO' AND p.status = 'SUCCESS')) " +
           "ORDER BY o.createdAt ASC")
    Page<Order> findAvailableOrdersForShippers(Pageable pageable);

    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN o.orderItems oi " +
           "WHERE (:storeId IS NULL OR o.store.id = :storeId OR oi.productUnitMapping.product.store.id = :storeId) " +
           "AND (:status IS NULL OR o.status = :status) " +
           "AND (:from IS NULL OR o.createdAt >= :from) " +
           "AND (:to IS NULL OR o.createdAt <= :to) " +
           "ORDER BY o.createdAt DESC")
    Page<Order> findAllWithFilters(@Param("storeId") Long storeId,
                                   @Param("status") OrderStatus status,
                                   @Param("from") LocalDateTime from,
                                   @Param("to") LocalDateTime to,
                                   Pageable pageable);

    /**
     * Tính tổng doanh thu từ các đơn hàng đã giao thành công (DELIVERED)
     * @return Tổng doanh thu (BigDecimal)
     */
    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.status = 'DELIVERED'")
    java.math.BigDecimal getTotalRevenue();

    /**
     * Tính tổng doanh thu trong khoảng thờ i gian
     */
    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.status = 'DELIVERED' AND o.createdAt >= :from AND o.createdAt < :to")
    java.math.BigDecimal getRevenueBetween(@Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /**
     * Tính tổng doanh thu và số đơn theo tháng (12 tháng gần nhất)
     */
    @Query(value = """
        SELECT 
            DATE_FORMAT(o.created_at, '%Y-%m') as month,
            SUM(o.total_amount) as revenue,
            COUNT(*) as order_count
        FROM orders o
        WHERE o.status = 'DELIVERED'
            AND o.created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
        GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
        ORDER BY month ASC
        """, nativeQuery = true)
    List<Object[]> getMonthlyRevenueLast12Months();

    /**
     * Đếm tổng số đơn hàng theo từng trạng thái
     * @param status Trạng thái đơn hàng
     * @return Số lượng đơn hàng
     */
    @Query("SELECT COUNT(o) FROM Order o WHERE o.status = :status")
    Long countByStatus(@Param("status") OrderStatus status);

    /**
     * Lấy tất cả đơn hàng, sắp xếp theo thời gian mới nhất
     * @return Danh sách đơn hàng
     */
    @Query("SELECT o FROM Order o ORDER BY o.createdAt DESC")
    List<Order> findAllOrdersSorted();

    /**
     * Lấy đơn hàng theo ID với đầy đủ thông tin JOIN FETCH
     * Giải quyết lazy loading storm khi map sang OrderResponse
     * Bao gồm: customer, shipper, orderItems → productUnitMapping → product → store
     * Lưu ý: payments dùng @BatchSize(50) vì không FETCH 2 collections cùng lúc
     */
    @Query("SELECT o FROM Order o " +
           "LEFT JOIN FETCH o.customer " +
           "LEFT JOIN FETCH o.shipper " +
           "LEFT JOIN FETCH o.orderItems oi " +
           "LEFT JOIN FETCH oi.productUnitMapping pum " +
           "LEFT JOIN FETCH pum.product p " +
           "LEFT JOIN FETCH p.store " +
           "WHERE o.id = :orderId")
    Optional<Order> findByIdWithFullDetails(@Param("orderId") Long orderId);

    /**
     * Lấy danh sách đơn hàng theo customer với đầy đủ JOIN FETCH
     * Dùng cho mapToOrderResponse batch - tránh N+1
     */
    @Query("SELECT DISTINCT o FROM Order o " +
           "LEFT JOIN FETCH o.customer " +
           "LEFT JOIN FETCH o.shipper " +
           "LEFT JOIN FETCH o.orderItems oi " +
           "LEFT JOIN FETCH oi.productUnitMapping pum " +
           "LEFT JOIN FETCH pum.product p " +
           "LEFT JOIN FETCH p.store " +
           "WHERE o.customer.id = :customerId " +
           "ORDER BY o.createdAt DESC")
    List<Order> findByCustomerIdWithDetails(@Param("customerId") Long customerId);

    /**
     * Lấy danh sách đơn hàng theo shipper với đầy đủ JOIN FETCH
     */
    @Query("SELECT DISTINCT o FROM Order o " +
           "LEFT JOIN FETCH o.customer " +
           "LEFT JOIN FETCH o.shipper " +
           "LEFT JOIN FETCH o.orderItems oi " +
           "LEFT JOIN FETCH oi.productUnitMapping pum " +
           "LEFT JOIN FETCH pum.product p " +
           "LEFT JOIN FETCH p.store " +
           "WHERE o.shipper.id = :shipperId " +
           "ORDER BY o.createdAt DESC")
    List<Order> findByShipperIdWithDetails(@Param("shipperId") Long shipperId);
}
