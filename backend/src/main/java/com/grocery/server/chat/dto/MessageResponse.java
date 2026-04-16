package com.grocery.server.chat.dto;

import com.grocery.server.chat.document.Message;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MessageResponse {
    private String id;
    private String conversationId;
    private Long senderId;
    private Message.SenderType senderType;
    private String content;
    private LocalDateTime timestamp;
    private boolean read;
}
