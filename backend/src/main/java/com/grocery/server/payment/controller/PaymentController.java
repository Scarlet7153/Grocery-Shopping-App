package com.grocery.server.payment.controller;

import com.grocery.server.payment.dto.InitiatePaymentRequest;
import com.grocery.server.payment.dto.InitiatePaymentResponse;
import com.grocery.server.payment.dto.PaymentStatusResponse;
import com.grocery.server.payment.entity.Payment;
import com.grocery.server.payment.service.PaymentService;
import com.grocery.server.payment.config.PaymentProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;
    private final com.grocery.server.payment.provider.MomoClient momoClient;
    private final com.grocery.server.payment.provider.VnPayClient vnpayClient;
    private final PaymentProperties paymentProperties;

    @PostMapping("/initiate")
    public ResponseEntity<?> initiate(@RequestBody InitiatePaymentRequest req) {
        Payment.PaymentMethod method = Payment.PaymentMethod.valueOf(req.getPaymentMethod());
        Payment payment = paymentService.initiatePayment(req.getOrderId(), method);

        String redirect = "";
        switch (method) {
            case MOMO -> redirect = momoClient.createPaymentUrl(payment);
            case VNPAY -> redirect = vnpayClient.createPaymentUrl(payment, null);
            case COD -> redirect = "";  // COD: no redirect needed, client will handle payment locally
            default -> redirect = "";
        }

        return ResponseEntity.ok(new InitiatePaymentResponse(payment.getId(), redirect));
    }

    /**
     * GET /api/payments/{id} - Retrieve payment status
     * Used by mobile app to check payment status without polling callback
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getPaymentStatus(@PathVariable Long id) {
        Payment payment = paymentService.findById(id)
                .orElse(null);
        if (payment == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(PaymentStatusResponse.fromEntity(payment));
    }

    /**
     * Endpoint giả lập callback Momo (POST)
     * Body: { paymentId, success, transactionCode }
     */
    @PostMapping("/momo/callback")
    public ResponseEntity<?> momoCallback(@RequestParam Map<String, String> params) {
        // Verify signature
        boolean ok = momoClient.verifyCallback(params);
        if (!ok) return ResponseEntity.status(400).body("Invalid signature");

        // Extract paymentId from extraData
        String extraData = params.get("extraData");
        Long paymentId = null;
        try { paymentId = Long.valueOf(extraData); } catch (Exception ignored) {}

        // Determine success by errorCode/resultCode (Momo uses resultCode == 0)
        String resultCode = params.getOrDefault("errorCode", params.getOrDefault("resultCode", ""));
        boolean success = "0".equals(resultCode) || "".equals(resultCode) && "0".equals(params.getOrDefault("resultCode", ""));
        String transactionCode = params.getOrDefault("transId", params.get("transactionCode"));

        if (paymentId == null) return ResponseEntity.status(400).body("Missing payment id");

        paymentService.handlePaymentResult(paymentId, success, transactionCode);
        return ResponseEntity.ok().build();
    }

    /**
     * Endpoint giả lập callback VNPay (GET/POST) - accept query params
     */
    @RequestMapping(value = "/vnpay/callback", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<?> vnpayCallback(@RequestParam Map<String, String> params) {
        // Verify signature
        boolean ok = vnpayClient.verifyCallback(params);
        if (!ok) return ResponseEntity.status(400).body("Invalid signature");

        // Extract paymentId from vnp_TxnRef (we set it as P{paymentId})
        String txnRef = params.get("vnp_TxnRef");
        Long paymentId = null;
        if (txnRef != null && txnRef.startsWith("P")) {
            try { paymentId = Long.valueOf(txnRef.substring(1)); } catch (Exception ignored) {}
        }

        if (paymentId == null) return ResponseEntity.status(400).body("Missing payment id");

        // success if vnp_ResponseCode == "00"
        boolean success = "00".equals(params.getOrDefault("vnp_ResponseCode", ""));
        String transactionCode = params.get("vnp_TransactionNo");

        paymentService.handlePaymentResult(paymentId, success, transactionCode);
        return ResponseEntity.ok().build();
    }

    /**
     * Return URL for Momo (user will be redirected here after payment)
     */
    @GetMapping("/momo/return")
    public ResponseEntity<?> momoReturn(@RequestParam Map<String, String> params) {
        boolean ok = momoClient.verifyCallback(params);
        if (!ok) return ResponseEntity.status(400).body("Invalid signature");

        String extraData = params.get("extraData");
        Long paymentId = null;
        try { paymentId = Long.valueOf(extraData); } catch (Exception ignored) {}
        if (paymentId == null) return ResponseEntity.status(400).body("Missing payment id");

        String resultCode = params.getOrDefault("errorCode", params.getOrDefault("resultCode", ""));
        boolean success = "0".equals(resultCode);

        String redirectBase = paymentProperties.getServerExternalBaseUrl();
        String target = String.format("%s/payment-result?paymentId=%d&success=%b", redirectBase, paymentId, success);
        return ResponseEntity.status(302).header("Location", target).build();
    }

    /**
     * Return URL for VNPay (user redirect)
     */
    @RequestMapping(value = "/vnpay/return", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<?> vnpayReturn(@RequestParam Map<String, String> params) {
        boolean ok = vnpayClient.verifyCallback(params);
        if (!ok) return ResponseEntity.status(400).body("Invalid signature");

        String txnRef = params.get("vnp_TxnRef");
        Long paymentId = null;
        if (txnRef != null && txnRef.startsWith("P")) {
            try { paymentId = Long.valueOf(txnRef.substring(1)); } catch (Exception ignored) {}
        }
        if (paymentId == null) return ResponseEntity.status(400).body("Missing payment id");

        boolean success = "00".equals(params.getOrDefault("vnp_ResponseCode", ""));
        String redirectBase = paymentProperties.getServerExternalBaseUrl();
        String target = String.format("%s/payment-result?paymentId=%d&success=%b", redirectBase, paymentId, success);
        return ResponseEntity.status(302).header("Location", target).build();
    }
}
