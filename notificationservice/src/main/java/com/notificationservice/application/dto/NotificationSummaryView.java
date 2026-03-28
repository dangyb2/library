package com.notificationservice.application.dto;

import com.notificationservice.domain.model.Notification; // Crucial import!
import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;
import java.time.Instant;

public record NotificationSummaryView(
        String id,
        String recipientEmail,
        NotificationType type,
        String subject,
        NotificationStatus status,
        int retryCount,
        Instant createdAt,
        Instant sentAt
) {
    // Change this to 'public static' so your service can use it
    public static NotificationSummaryView fromDomain(Notification n) {
        return new NotificationSummaryView(
                n.getId(),
                n.getRecipientEmail(),
                n.getType(),
                n.getSubject(),
                n.getStatus(),
                n.getRetryCount(),
                n.getCreatedAt(),
                n.getSentAt()
        );
    }
}