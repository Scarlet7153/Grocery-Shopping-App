package com.grocery.server.payment.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "payment")
public class PaymentProperties {
    private Momo momo;
    private VnPay vnpay;
    private String serverExternalBaseUrl;

    @Data
    public static class Momo {
        private String partnerCode;
        private String accessKey;
        private String secretKey;
        private String requestUrl;
        private String returnUrl;
        private String notifyUrl;
    }

    @Data
    public static class VnPay {
        private String tmnCode;
        private String secretKey;
        private String url;
        private String returnUrl;
    }
}
