package com.notificationservice.infrastructure.dto;

import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;

import java.time.Instant;

public record NotificationDetailsResponse(
        String id,
        String recipientEmail,
        NotificationType type,
        NotificationStatus status,
        int retryCount,
        Instant createdAt,
        Instant sentAt
) {
}
