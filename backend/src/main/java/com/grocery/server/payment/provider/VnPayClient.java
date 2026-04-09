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
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Component
@RequiredArgsConstructor
@Slf4j
public class VnPayClient {

    private final PaymentProperties paymentProperties;

    public String createPaymentUrl(Payment payment, String ipAddress) {
        PaymentProperties.VnPay conf = paymentProperties.getVnpay();

        String vnp_Version = "2.1.0";
        String vnp_Command = "pay";
        String vnp_TmnCode = conf.getTmnCode();
        String vnp_TxnRef = "P" + payment.getId();
        String vnp_OrderInfo = "Thanh toan don " + payment.getOrder().getId();
        String vnp_OrderType = "other";
        String vnp_Locale = "vn";
        String vnp_CurrCode = "VND";
        String vnp_Amount = String.valueOf(payment.getAmount().multiply(java.math.BigDecimal.valueOf(100)).longValue());
        String vnp_ReturnUrl = conf.getReturnUrl();
        String vnp_CreateDate = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));

        Map<String, String> vnpParams = new HashMap<>();
        vnpParams.put("vnp_Version", vnp_Version);
        vnpParams.put("vnp_Command", vnp_Command);
        vnpParams.put("vnp_TmnCode", vnp_TmnCode);
        vnpParams.put("vnp_TxnRef", vnp_TxnRef);
        vnpParams.put("vnp_OrderInfo", vnp_OrderInfo);
        vnpParams.put("vnp_OrderType", vnp_OrderType);
        vnpParams.put("vnp_Amount", vnp_Amount);
        vnpParams.put("vnp_ReturnUrl", vnp_ReturnUrl);
        vnpParams.put("vnp_Locale", vnp_Locale);
        vnpParams.put("vnp_CreateDate", vnp_CreateDate);
        if (ipAddress != null) vnpParams.put("vnp_IpAddr", ipAddress);

        // sort and build data
        List<String> fieldNames = new ArrayList<>(vnpParams.keySet());
        Collections.sort(fieldNames);

        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();
        for (String name : fieldNames) {
            String value = vnpParams.get(name);
            if (hashData.length() > 0) {
                hashData.append('&');
            }
            hashData.append(name).append('=').append(value);
            query.append(urlEncode(name)).append('=').append(urlEncode(value)).append('&');
        }

        String vnpSecureHash = hmacSHA512(conf.getSecretKey(), hashData.toString());
        query.append("vnp_SecureHash=").append(vnpSecureHash);

        String paymentUrl = conf.getUrl() + "?" + query.toString();
        log.debug("VNPay URL: {}", paymentUrl);
        return paymentUrl;
    }

    /**
     * Verify VNPay callback signature (vnp_SecureHash)
     */
    public boolean verifyCallback(Map<String, String> params) {
        PaymentProperties.VnPay conf = paymentProperties.getVnpay();
        String receivedHash = params.get("vnp_SecureHash");
        if (receivedHash == null) return false;

        // Remove vnp_SecureHash and vnp_SecureHashType from params when computing
        Map<String, String> copy = new HashMap<>(params);
        copy.remove("vnp_SecureHash");
        copy.remove("vnp_SecureHashType");

        List<String> fieldNames = new ArrayList<>(copy.keySet());
        Collections.sort(fieldNames);

        StringBuilder hashData = new StringBuilder();
        for (String name : fieldNames) {
            String value = copy.get(name);
            if (value == null || value.isEmpty()) continue;
            if (hashData.length() > 0) hashData.append('&');
            hashData.append(name).append('=').append(value);
        }

        String expected = hmacSHA512(conf.getSecretKey(), hashData.toString());
        return expected.equalsIgnoreCase(receivedHash);
    }

    private static String urlEncode(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    private static String hmacSHA512(String key, String data) {
        try {
            Mac sha512_HMAC = Mac.getInstance("HmacSHA512");
            SecretKeySpec secret_key = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA512");
            sha512_HMAC.init(secret_key);
            byte[] hash = sha512_HMAC.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(2 * hash.length);
            for (byte b : hash) sb.append(String.format("%02x", b & 0xff));
            return sb.toString();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
}
