package com.grocery.server.chat.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Message {

    @Id
    private String id;

    @Indexed
    private String conversationId;

    private Long senderId;

    private SenderType senderType;

    private String content;

    @Indexed
    private LocalDateTime timestamp;

    private boolean read;

    public enum SenderType {
        SHIPPER,
        CUSTOMER
    }
}
