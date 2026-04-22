package com.grocery.server.order.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * DTO: Thống kê đơn hàng cho Dashboard Admin
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderStatisticsResponse {

    /**
     * Doanh thu tháng hiện tại
     */
    private BigDecimal currentMonthRevenue;

    /**
     * Doanh thu tháng trước
     */
    private BigDecimal previousMonthRevenue;

    /**
     * Phần trăm thay đổi so với tháng trước
     */
    private Double monthOverMonthGrowth;

    /**
     * Tổng doanh thu từ trước đến nay
     */
    private BigDecimal totalRevenue;

    /**
     * Tổng số đơn hàng
     */
    private Long totalOrders;

    /**
     * Doanh thu theo từng tháng (12 tháng gần nhất)
     */
    private List<MonthlyRevenueDto> monthlyRevenue;

    /**
     * DTO con: Doanh thu 1 tháng
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MonthlyRevenueDto {
        private String month;      // Format: yyyy-MM
        private String monthLabel; // Format: T5/2025
        private BigDecimal revenue;
        private Long orderCount;
    }
}
