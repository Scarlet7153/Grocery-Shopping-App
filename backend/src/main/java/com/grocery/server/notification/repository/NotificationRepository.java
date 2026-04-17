package com.grocery.server.notification.repository;

import com.grocery.server.notification.document.Notification;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends MongoRepository<Notification, String> {

    /** Lấy tất cả thông báo của user, mới nhất trước */
    List<Notification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId);

    /** Chỉ lấy thông báo chưa đọc */
    List<Notification> findByRecipientIdAndIsReadFalseOrderByCreatedAtDesc(Long recipientId);

    /** Đếm thông báo chưa đọc */
    long countByRecipientIdAndIsReadFalse(Long recipientId);

    /**
     * Xóa tất cả thông báo của user (dùng nếu cần).
     * MongoDB không cần @Modifying hay @Query JPQL.
     */
    void deleteByRecipientId(Long recipientId);
}
