package com.grocery.server.payment.dto;

import lombok.Data;

import java.io.Serializable;

@Data
public class InitiatePaymentRequest implements Serializable {
    private Long orderId;
    private String paymentMethod; // MOMO or VNPAY
}
