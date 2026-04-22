package com.grocery.server.order.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: StoreInfoResponse
 * Mô tả: Thông tin cửa hàng trong đơn hàng (dùng cho đơn liên cửa hàng)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreInfoResponse {

    private Long id;
    private String name;
    private String address;
}
