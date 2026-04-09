Payment integration (Momo & VNPay)
=================================

Setup
------
- Fill payment provider credentials in `backend/src/main/resources/application.properties`:

```
payment.momo.partnerCode=... 
payment.momo.accessKey=...
payment.momo.secretKey=...
payment.momo.requestUrl=https://test-payment.momo.vn/v2/gateway/api/create

payment.vnpay.tmnCode=...
payment.vnpay.secretKey=...
payment.vnpay.url=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
```

How it works
------------
- `POST /api/payments/initiate` with body `{ "orderId": <id>, "paymentMethod": "MOMO"|"VNPAY" }` creates a `Payment` record (status=PENDING) and returns `paymentId` + `redirectUrl`.
- Client should open `redirectUrl` in a browser or WebView. After user completes payment provider will call:
  - notify/callback (server-to-server) -> `/api/payments/momo/callback` or `/api/payments/vnpay/callback`
  - user return (browser redirect) -> `/api/payments/momo/return` or `/api/payments/vnpay/return`

Security
--------
- Callbacks are verified using HMAC signatures: Momo HMAC-SHA256, VNPay HMAC-SHA512.

DB Migration
------------
Run the SQL in `backend/src/main/resources/db/migration/V2__add_payment_status_and_vnpay.sql` on your database (backup first).

Mobile integration (Flutter)
----------------------------
- Call initiate endpoint and open returned `redirectUrl` in an in-app browser or external browser.
- On return, the provider will redirect to the server return URL which in turn redirects to `server.externalBaseUrl/payment-result?...`. Implement a route in the mobile app to handle deep-linking or poll backend for payment status.

Testing locally
---------------
- Launch backend; create an order; call `POST /api/payments/initiate` to get `redirectUrl`.
- Use sandbox/simulators from providers or simulate provider callbacks by calling the callback endpoints (note: signature verification requires correctly formed params and secret).
