package com.notificationservice.application.dto;

import com.notificationservice.domain.model.Notification;
import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;
import java.time.Instant;

public record NotificationDetailView(
        String id,
        String recipientEmail,
        NotificationType type,
        String subject,
        String content, //
        NotificationStatus status,
        int retryCount,
        Instant createdAt,
        Instant sentAt
) {
    public static NotificationDetailView fromDomain(Notification n) {
        return new NotificationDetailView(
                n.getId(),
                n.getRecipientEmail(),
                n.getType(),
                n.getSubject(),
                n.getContent(),
                n.getStatus(),
                n.getRetryCount(),
                n.getCreatedAt(),
                n.getSentAt()
        );
    }
}