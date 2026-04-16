package com.grocery.server.chat.repository;

import com.grocery.server.chat.document.Conversation;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends MongoRepository<Conversation, String> {

    Optional<Conversation> findByOrderId(Long orderId);

    List<Conversation> findByShipperIdOrderByUpdatedAtDesc(Long shipperId);

    List<Conversation> findByCustomerIdOrderByUpdatedAtDesc(Long customerId);

    boolean existsByOrderId(Long orderId);
}
