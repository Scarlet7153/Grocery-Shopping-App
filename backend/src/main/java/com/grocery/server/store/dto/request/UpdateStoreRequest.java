package com.grocery.server.store.dto.request;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO Request: UpdateStoreRequest
 * Mục đích: Nhận dữ liệu cập nhật thông tin cửa hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateStoreRequest {

    @Size(max = 100, message = "Tên cửa hàng không được quá 100 ký tự")
    private String storeName;

    @Size(max = 500, message = "Địa chỉ không được quá 500 ký tự")
    private String address;

    private String imageUrl;
}
