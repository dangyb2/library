package com.notificationservice.infrastructure.dto;

import com.notificationservice.domain.model.NotificationStatus;

import java.time.Instant;

public record NotificationEventResponse(
        String id,
        NotificationStatus status,
        int retryCount,
        Instant sentAt
) {
}
