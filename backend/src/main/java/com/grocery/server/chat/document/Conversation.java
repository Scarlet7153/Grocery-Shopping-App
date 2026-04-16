package com.grocery.server.chat.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "conversations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Conversation {

    @Id
    private String id;

    @Indexed
    private Long orderId;

    @Indexed
    private Long shipperId;

    @Indexed
    private Long customerId;

    private String shipperName;
    private String customerName;

    private String lastMessage;
    private LocalDateTime lastMessageAt;

    @Indexed
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
