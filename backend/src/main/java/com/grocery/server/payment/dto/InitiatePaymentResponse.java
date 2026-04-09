package com.grocery.server.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.io.Serializable;

@Data
@AllArgsConstructor
public class InitiatePaymentResponse implements Serializable {
    private Long paymentId;
    private String redirectUrl;
}
