package com.grocery.server.order.repository;

import com.grocery.server.order.entity.Order;
import com.grocery.server.order.entity.Order.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

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
     * Lấy tất cả đơn hàng của một cửa hàng
     * @param storeId ID cửa hàng
     * @return Danh sách đơn hàng, sắp xếp theo thời gian mới nhất
     */
    @Query("SELECT o FROM Order o WHERE o.store.id = :storeId ORDER BY o.createdAt DESC")
    List<Order> findByStoreId(@Param("storeId") Long storeId);

    /**
     * Lấy tất cả đơn hàng của một tài xế
     * @param shipperId ID tài xế
     * @return Danh sách đơn hàng, sắp xếp theo thời gian mới nhất
     */
    @Query("SELECT o FROM Order o WHERE o.shipper.id = :shipperId ORDER BY o.createdAt DESC")
    List<Order> findByShipperId(@Param("shipperId") Long shipperId);

    /**
     * Lấy đơn hàng theo trạng thái của một cửa hàng
     * @param storeId ID cửa hàng
     * @param status Trạng thái đơn hàng
     * @return Danh sách đơn hàng
     */
    @Query("SELECT o FROM Order o WHERE o.store.id = :storeId AND o.status = :status ORDER BY o.createdAt DESC")
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
    @Query("SELECT COUNT(o) FROM Order o WHERE o.store.id = :storeId AND o.status = :status")
    Long countByStoreIdAndStatus(@Param("storeId") Long storeId, @Param("status") OrderStatus status);

    /**
     * Lấy tất cả đơn hàng đang chờ tài xế nhận (CONFIRMED)
     * @return Danh sách đơn hàng chưa có shipper và đang ở trạng thái CONFIRMED
     */
    @Query("SELECT o FROM Order o WHERE o.status = 'CONFIRMED' AND o.shipper IS NULL ORDER BY o.createdAt ASC")
    List<Order> findAvailableOrdersForShippers();

    /**
     * Tính tổng doanh thu từ các đơn hàng đã giao thành công (DELIVERED)
     * @return Tổng doanh thu (BigDecimal)
     */
    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.status = 'DELIVERED'")
    java.math.BigDecimal getTotalRevenue();

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
}
