package com.grocery.server.payment.provider;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.grocery.server.payment.config.PaymentProperties;
import com.grocery.server.payment.entity.Payment;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class MomoClient {

    private final PaymentProperties paymentProperties;
    private final ObjectMapper objectMapper;

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
        params.put("redirectUrl", conf.getReturnUrl());
        params.put("ipnUrl", conf.getNotifyUrl());
        params.put("extraData", String.valueOf(payment.getId()));
        params.put("requestType", "captureWallet");

        String raw = buildRawString(params);
        String signature = hmacSHA256(conf.getSecretKey(), raw);
        params.put("signature", signature);

        try {
            String requestBody = objectMapper.writeValueAsString(params);
            log.debug("Momo create payment request body: {}", requestBody);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(conf.getRequestUrl()))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                    .build();

            HttpResponse<String> response = HttpClient.newHttpClient()
                    .send(request, HttpResponse.BodyHandlers.ofString());
            log.debug("Momo create payment response status={}, body={}", response.statusCode(), response.body());

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                Map<String, Object> result = objectMapper.readValue(
                        response.body(), new TypeReference<>() {
                        });
                if (result != null && "0".equals(String.valueOf(result.get("resultCode")))) {
                    String deeplink = String.valueOf(result.getOrDefault("deeplink", ""));
                    String payUrl = String.valueOf(result.getOrDefault("payUrl", ""));
                    String chosenUrl = (deeplink != null && !deeplink.isEmpty()) ? deeplink : payUrl;
                    log.info("Momo payment created for payment #{}: {}", payment.getId(), chosenUrl);
                    return chosenUrl;
                }
                log.warn("Momo create payment failed: {}", response.body());
                throw new RuntimeException("Momo payment creation failed: " + response.body());
            }
            throw new RuntimeException("Momo create API call failed with status " + response.statusCode() + ": " + response.body());
        } catch (Exception ex) {
            log.error("Error while creating MoMo payment", ex);
            throw new RuntimeException(ex);
        }
    }

    /**
     * Verify callback params from Momo using secretKey and returned signature.
     * MoMo IPN callback uses pipe-separated signature format.
     * Signature fields: partnerCode|orderId|requestId|amount|errorCode|transId|message|localMessage|responseTime|payType|extraData
     */
    public boolean verifyCallback(Map<String, String> params) {
        PaymentProperties.Momo conf = paymentProperties.getMomo();
        String signature = params.get("signature");
        if (signature == null || signature.isEmpty()) {
            return false;
        }

        String raw = String.join("|",
                nvl(params.get("partnerCode")),
                nvl(params.get("orderId")),
                nvl(params.get("requestId")),
                nvl(params.get("amount")),
                nvl(params.get("errorCode")),
                nvl(params.get("transId")),
                nvl(params.get("message")),
                nvl(params.get("localMessage")),
                nvl(params.get("responseTime")),
                nvl(params.get("payType")),
                nvl(params.get("extraData"))
        );

        String expected = hmacSHA256(conf.getSecretKey(), raw);
        return expected.equals(signature);
    }

    private String nvl(String s) {
        return s == null ? "" : s;
    }

    private static String buildRawString(Map<String, String> params) {
        StringBuilder sb = new StringBuilder();
        params.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .forEach(entry -> {
                    if (sb.length() > 0) sb.append("&");
                    sb.append(entry.getKey()).append("=").append(entry.getValue());
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
