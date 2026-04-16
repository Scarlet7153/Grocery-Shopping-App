package com.grocery.server.chat.repository;

import com.grocery.server.chat.document.Message;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends MongoRepository<Message, String> {

    List<Message> findByConversationIdOrderByTimestampAsc(String conversationId);

    long countByConversationIdAndReadFalseAndSenderTypeNot(
            String conversationId, Message.SenderType senderType);
}
