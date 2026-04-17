package com.grocery.server.notification.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

/**
 * MongoDB Document: notifications
 * Database: grocery_chat (cùng với chat module)
 * Lưu lịch sử thông báo cho Customer, Store Owner, Shipper.
 */
@Document(collection = "notifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    private String id;                // MongoDB ObjectId dạng String

    /** ID người nhận (userId trong MySQL) */
    @Indexed
    private Long recipientId;

    /**
     * Phone number của người nhận.
     * Dùng làm WebSocket principal (khớp với ChatService.notifyConversationListUpdate)
     */
    @Indexed
    private String recipientPhone;

    /** Loại thông báo */
    private String type;              // Dùng String thay enum để linh hoạt hơn

    /** Tiêu đề hiển thị trên app */
    private String title;

    /** Nội dung chi tiết */
    private String body;

    /** ID tham chiếu (orderId, reviewId...) */
    private Long referenceId;

    /** Loại tham chiếu: "ORDER", "REVIEW" */
    private String referenceType;

    /** Trạng thái đã đọc */
    @Builder.Default
    private boolean isRead = false;

    @Indexed
    private LocalDateTime createdAt;

    // ─── Notification type constants ───────────────────────────
    public static final String ORDER_CREATED    = "ORDER_CREATED";
    public static final String ORDER_CONFIRMED  = "ORDER_CONFIRMED";
    public static final String ORDER_PICKING_UP = "ORDER_PICKING_UP";
    public static final String ORDER_DELIVERING = "ORDER_DELIVERING";
    public static final String ORDER_DELIVERED  = "ORDER_DELIVERED";
    public static final String ORDER_CANCELLED  = "ORDER_CANCELLED";
    public static final String SHIPPER_ASSIGNED = "SHIPPER_ASSIGNED";
    public static final String NEW_REVIEW       = "NEW_REVIEW";
    public static final String REVIEW_REPLIED   = "REVIEW_REPLIED";
}
