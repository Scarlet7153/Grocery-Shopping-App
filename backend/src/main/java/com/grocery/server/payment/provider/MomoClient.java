package com.grocery.server.payment.provider;

import com.grocery.server.payment.config.PaymentProperties;
import com.grocery.server.payment.entity.Payment;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class MomoClient {

    private final PaymentProperties paymentProperties;

    public String createPaymentUrl(Payment payment) {
        PaymentProperties.Momo conf = paymentProperties.getMomo();
        String requestId = String.valueOf(System.currentTimeMillis());
        String orderId = "ORDER" + payment.getOrder().getId() + "-P" + payment.getId();
        String amount = payment.getAmount().toBigInteger().toString();
        String orderInfo = "Thanh toan don hang " + payment.getOrder().getId();

        Map<String, String> params = new LinkedHashMap<>();
        params.put("partnerCode", conf.getPartnerCode());
        params.put("accessKey", conf.getAccessKey());
        params.put("requestId", requestId);
        params.put("amount", amount);
        params.put("orderId", orderId);
        params.put("orderInfo", orderInfo);
        params.put("returnUrl", conf.getReturnUrl());
        params.put("notifyUrl", conf.getNotifyUrl());
        params.put("extraData", String.valueOf(payment.getId()));

        String raw = buildRawString(params);
        String signature = hmacSHA256(conf.getSecretKey(), raw);

        // Build redirect to Momo create API (server-to-server) with body; here we return a web URL with params for simplicity
        StringBuilder sb = new StringBuilder(conf.getRequestUrl());
        sb.append("?");
        params.forEach((k, v) -> {
            sb.append(urlEncode(k)).append("=").append(urlEncode(v)).append("&");
        });
        sb.append("signature=").append(urlEncode(signature));

        log.debug("Momo payment url prepared: {}", sb.toString());
        return sb.toString();
    }

    /**
     * Verify callback params from Momo using secretKey and returned signature
     */
    public boolean verifyCallback(Map<String, String> params) {
        PaymentProperties.Momo conf = paymentProperties.getMomo();
        String signature = params.get("signature");
        // Build raw string in the same order used when creating signature
        Map<String, String> signedFields = new LinkedHashMap<>();
        signedFields.put("partnerCode", params.get("partnerCode"));
        signedFields.put("accessKey", params.get("accessKey"));
        signedFields.put("requestId", params.get("requestId"));
        signedFields.put("amount", params.get("amount"));
        signedFields.put("orderId", params.get("orderId"));
        signedFields.put("orderInfo", params.get("orderInfo"));
        signedFields.put("orderType", params.getOrDefault("orderType", ""));
        signedFields.put("transId", params.getOrDefault("transId", ""));
        signedFields.put("message", params.getOrDefault("message", ""));
        signedFields.put("localMessage", params.getOrDefault("localMessage", ""));
        signedFields.put("responseTime", params.getOrDefault("responseTime", ""));
        signedFields.put("errorCode", params.getOrDefault("errorCode", ""));
        signedFields.put("payType", params.getOrDefault("payType", ""));
        signedFields.put("extraData", params.getOrDefault("extraData", ""));

        String raw = buildRawString(signedFields);
        String expected = hmacSHA256(conf.getSecretKey(), raw);
        return expected.equals(signature);
    }

    private static String buildRawString(Map<String, String> params) {
        StringBuilder sb = new StringBuilder();
        params.forEach((k, v) -> {
            if (sb.length() > 0) sb.append("&");
            sb.append(k).append("=").append(v);
        });
        return sb.toString();
    }

    private static String urlEncode(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    private static String hmacSHA256(String key, String data) {
        try {
            Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
            SecretKeySpec secret_key = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            sha256_HMAC.init(secret_key);
            byte[] hash = sha256_HMAC.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(2 * hash.length);
            for (byte b : hash) sb.append(String.format("%02x", b & 0xff));
            return sb.toString();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
}
